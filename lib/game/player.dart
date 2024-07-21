import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/functions.dart';
import '../util/keys.dart';
import '../util/messaging.dart';
import '../util/on_message.dart';
import 'game_context.dart';
import 'game_messages.dart';

enum PlayerState {
  gone,
  entering,
  playing,
  leaving,
  dying,
  ;

  static PlayerState from(final String name) => PlayerState.values.firstWhere((e) => e.name == name);
}

class Player extends SpriteComponent with AutoDispose, GameContext, HasVisibility {
  Player() : super(anchor: const Anchor(0.5, 0.8)) {
    player = this;
  }

  late final Keys _keys;
  late final SpriteSheet _sprites;

  late TiledMap _map;

  var _state = PlayerState.gone;
  var _state_progress = 0.0;

  double _anim_time = 0;

  // ignore: prefer_final_fields
  double _move_speed = 100;

  final _move_dir = Vector2.zero();

  void reset(PlayerState reset_state) {
    logInfo('reset player: $reset_state');
    _state = reset_state;
    _state_progress = 0.0;
    position.setValues(center_x, game_height + height);
  }

  @override
  bool get isVisible => _state != PlayerState.gone;

  @override
  Future onLoad() async {
    super.onLoad();

    paint = pixel_paint();
    paint.style = PaintingStyle.stroke;

    _keys = keys;
    _sprites = await sheetIWH('characters.png', 16, 32);
    this.sprite = _sprites.getSpriteById(0);

    onMessage<EnterRound>((_) => reset(PlayerState.gone));
    onMessage<GameComplete>((_) => _on_level_complete());
    onMessage<LevelComplete>((_) => _on_level_complete());
    onMessage<LevelDataAvailable>((it) => _map = it.map);
    onMessage<LevelReady>((_) => reset(PlayerState.entering));
  }

  _on_level_complete() => _state = PlayerState.leaving;

  @override
  void update(double dt) {
    super.update(dt);
    switch (_state) {
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
        _on_fire_weapon(dt);
        _update(dt);
    }
  }

  void _on_entering(double dt) {
    _state_progress += dt;
    if (_state_progress > 1.0) {
      _move_dir.setZero();
      _state_progress = 1.0;
      _state = PlayerState.playing;
      sendMessage(PlayerReady());
    } else {
      _move_dir.setValues(0, -1);
    }
  }

  void _update(double dt) {
    if (!_move_dir.isZero()) _animate_movement(dt);

    _move_dir.scale(_move_speed * dt);
    position.add(_move_dir);

    priority = position.y.toInt();

    final top = -(_map.height - 15) * 16.0;
    _move_dir.setValues(0, (position.y - 128).clamp(top, 0.0));

    game.camera.moveTo(_move_dir);
  }

  void _animate_movement(double dt) {
    _anim_time += dt * 2.5;

    if (_anim_time >= 1) _anim_time -= 1;
    final frame = (_anim_time * 4).toInt().clamp(0, 3);
    var offset = 0;
    if (_move_dir.y == 0) {
      if (_move_dir.x < 0) offset = 8;
      if (_move_dir.x > 0) offset = 12;
    }
    if (_move_dir.y < 0) offset = 0;
    if (_move_dir.y > 0) offset = 4;
    this.sprite = _sprites.getSpriteById(offset + frame);
  }

  void _on_leaving(double dt) {
    _state_progress -= dt;
    if (_state_progress < 0.0) {
      paint.color = transparent;
      _state_progress = 0.0;
      reset(PlayerState.gone);
    }
  }

  void _on_dying(double dt) {
    _state_progress += dt;
    if (_state_progress > 1.0) {
      _state_progress = 0.0;
      _state = PlayerState.gone;
      sendMessage(PlayerDied());
    }
  }

  void _on_move_player(double dt) {
    _move_dir.setZero();

    if (_keys.check(GameKey.left)) _move_dir.x -= 1;
    if (_keys.check(GameKey.right)) _move_dir.x += 1;
    if (_keys.check(GameKey.up)) _move_dir.y -= 1;
    if (_keys.check(GameKey.down)) _move_dir.y += 1;
  }

  void _on_fire_weapon(double dt) {
    // _was_holding_fire |= _keys.fire1;
    //
    // if (!_was_holding_fire || _keys.fire1) return;
    //
    // final caught = balls.where((it) => it.state == BallState.caught).firstOrNull;
    // if (caught != null) {
    //   _was_holding_fire = false;
    //   caught.push(x_speed * 0.5, -configuration.opt_ball_speed * 0.5);
    //   _force_hold.remove(caught);
    // } else if (caught == null && in_laser_mode) {
    //   _was_holding_fire = false;
    //
    //   _laser_pos.setFrom(position);
    //   _laser_pos.x -= bat_width / 4;
    //   model.laser.spawn(_laser_pos);
    //
    //   _laser_pos.setFrom(position);
    //   _laser_pos.x += bat_width / 4;
    //   model.laser.spawn(_laser_pos);
    //
    //   soundboard.trigger(Sound.laser_shot);
    //
    //   mode_time -= min(mode_time, 1);
    //   if (mode_time <= 0) _on_mode_reset();
    // }
    //
    // _was_holding_fire = false;
  }

// @override
// void render(Canvas canvas) {
//   super.render(canvas);
//   // switch (state) {
//   //   case PlayerState.gone:
//   //     break;
//   //   case PlayerState.entering:
//   //     _render_player(canvas);
//   //     break;
//   //   case PlayerState.leaving:
//   //     _render_player(canvas);
//   //     break;
//   //   case PlayerState.dying:
//   //     // final frame = (state_progress * (explosion.columns - 1)).round();
//   //     // if (frame < 5) _render_bat(canvas);
//   //     // explosion.getSpriteById(frame).render(canvas, overridePaint: paint, anchor: Anchor.center);
//   //     break;
//   //   case PlayerState.playing:
//   //     _render_player(canvas);
//   //     break;
//   // }
//
//   _render_player(canvas);
// }

// void _render_player(Canvas canvas) {
//   _sprites.getSpriteById(0).render(canvas, overridePaint: paint, anchor: Anchor.center);
// }
}
