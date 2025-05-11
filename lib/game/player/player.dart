import 'dart:math';
import 'dart:ui';

import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/particles.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/player_state.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

extension GameContextExtensions on GameContext {
  Player get player => cache.putIfAbsent('player', () => Player());
}

class Player extends SpriteComponent with AutoDispose, GameContext, HasAutoDisposeShortcuts, HasVisibility {
  Player() : super(anchor: const Anchor(0.5, 0.8));

  late final SpriteSheet _sprites1632;

  final bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);

  final fire_dir = Vector2.zero();
  final move_dir = Vector2.zero();
  final _temp_move = Vector2.zero();
  final _check_pos = Vector2.zero();
  final _last_free = Vector2.zero();

  late TiledMap _map;

  var state = PlayerState.gone;
  var state_progress = 0.0;
  double anim_time = 0;
  double show_firing = 0;
  double move_speed = configuration.player_move_speed;

  BaseWeapon? active_weapon;

  void reset(PlayerState reset_state) {
    log_info('reset player: $reset_state');
    state = reset_state;
    state_progress = 0.0;
    position.setValues(center_x, game_height + height);
  }

  @override
  bool get isVisible => state != PlayerState.gone;

  @override
  Future onLoad() async {
    super.onLoad();

    _sprites1632 = atlas.sheetIWH('tileset', 16, 32);

    paint = pixel_paint();
    paint.style = PaintingStyle.stroke;

    sprite = _sprites1632.getSpriteById(0);
  }

  @override
  void onMount() {
    super.onMount();
    on_message<EnterRound>((_) => reset(PlayerState.gone));
    on_message<GameComplete>((_) => _on_level_complete());
    on_message<LevelComplete>((_) => _on_level_complete());
    on_message<LevelDataAvailable>((it) => _map = it.map);
    on_message<LevelReady>((_) => reset(PlayerState.entering));
  }

  void _on_level_complete() => state = PlayerState.leaving;

  @override
  void update(double dt) {
    super.update(dt);
    anchor = Anchor(0.5, 0.8);
    switch (state) {
      case PlayerState.gone:
        break;
      case PlayerState.entering:
        _on_entering(dt);
        _update(dt);
      case PlayerState.leaving:
        _on_leaving(dt);
        _update(dt);
      case PlayerState.dying:
        _on_dying(dt);
      case PlayerState.playing:
        // if (phase != GamePhase.game_on) return;
        _on_move_player(dt);
        _update(dt);
    }
  }

  void _on_entering(double dt) {
    state_progress += dt;
    if (dev) state_progress += dt * 3;
    if (state_progress > 1.0) {
      move_dir.setZero();
      state_progress = 1.0;
      state = PlayerState.playing;
      send_message(PlayerReady());
    } else {
      move_dir.setValues(0, -1);
      if (dev) move_dir.setValues(0, -4);
    }
  }

  void _update(double dt) {
    final moving = !move_dir.isZero();
    if (moving) {
      fire_dir.setFrom(move_dir);
      _animate_movement(dt);
    }

    _update_position(dt);
    _update_sprite();

    show_firing -= min(show_firing, dt);
  }

  void _animate_movement(double dt) {
    anim_time += dt * 2.5;
    if (anim_time >= 1) anim_time -= 1;
  }

  void _update_position(double dt) {
    _temp_move.setFrom(move_dir);
    _temp_move.scale(move_speed * dt);
    position.add(_temp_move);

    priority = position.y.toInt() + 1;

    final top = -(_map.height - 15) * 16.0;
    _temp_move.setValues(0, (position.y - 128).clamp(top, 0.0));

    _temp_move.y = _temp_move.y.roundToDouble();
    game.camera.moveTo(_temp_move);

    bounds.left = position.x - 7;
    bounds.top = position.y - height * 1.25;
    bounds.width = 14;
    bounds.height = height * 1.5;

    for (final it in entities.consumables) {
      if (it.isRemoving || it.isRemoved) continue;
      if (!it.is_hit_by(position)) continue;
      particles.spawn_sparkles_for(it);
      soundboard.play(Sound.collect);
      it.removeFromParent();
      send_message(Collected(it));
      break;
    }
  }

  void _update_sprite() {
    final frame = (anim_time * 4).toInt().clamp(0, 3);

    var offset = 0;
    if (fire_dir.y == 0) {
      if (fire_dir.x < 0) offset = 8;
      if (fire_dir.x > 0) offset = 12;
    }
    if (fire_dir.y < 0) offset = 0;
    if (fire_dir.y > 0) offset = 4;

    final weapon = active_weapon?.type.index ?? 0;
    final firing = show_firing > 0 ? 16 : 0;
    sprite = _sprites1632.getSprite(12 + weapon, 16 + offset + frame + firing);
  }

  void _on_leaving(double dt) {
    state_progress -= dt;
    if (state_progress < 0.0) {
      paint.color = transparent;
      state_progress = 0.0;
      reset(PlayerState.gone);
    }
  }

  void _on_dying(double dt) {
    state_progress += dt;
    if (state_progress > 1.0) {
      state_progress = 0.0;
      state = PlayerState.gone;
      send_message(PlayerDied());
    }
  }

  void _on_move_player(double dt) {
    move_dir.setZero();

    if (keys.check(GameKey.left)) move_dir.x -= 1;
    if (keys.check(GameKey.right)) move_dir.x += 1;
    if (keys.check(GameKey.up)) move_dir.y -= 1;
    if (keys.check(GameKey.down)) move_dir.y += 1;

    _try_move(dt);
  }

  void _try_move(double dt) {
    move_dir.normalize();

    _temp_move.setFrom(move_dir);
    _temp_move.scale(configuration.player_move_speed * dt);
    _check_pos.setFrom(position);
    _check_pos.add(_temp_move);

    bounds.left = _check_pos.x - 7;
    bounds.top = _check_pos.y;
    bounds.width = 14;
    bounds.height = height * 0.125;

    for (final it in entities.obstacles) {
      if (it.is_blocked_for_walking(bounds)) {
        if (move_dir.x != 0 && move_dir.y != 0) {
          final remember_y = move_dir.y;

          move_dir.y = 0;
          move_dir.x = move_dir.x.sign;
          _try_move(dt);

          if (move_dir.isZero()) {
            move_dir.y = remember_y.sign;
            move_dir.x = 0;
            _try_move(dt);
          }

          return;
        }
        move_dir.setZero();
        position.setFrom(_last_free);
        priority = position.y.toInt() + 1;
        return;
      }
    }

    _last_free.setFrom(_check_pos);
  }
}
