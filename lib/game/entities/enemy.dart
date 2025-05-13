import 'dart:async';
import 'dart:math';

import 'package:commando24/game/entities/auto_animation.dart';
import 'package:commando24/game/entities/movement_down_only.dart';
import 'package:commando24/game/entities/movement_stationary.dart';
import 'package:commando24/game/entities/property_behavior.dart';
import 'package:commando24/game/entities/spawn_when_visible.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/level/level.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/util/random.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Enemy extends PositionComponent with PropertyBehavior, GameContext {
  Enemy(this.sprites);

  final SpriteSheet sprites;

  bool active = false;
  bool stationary = false;

  WeaponType? active_weapon;
  double show_firing = 0;

  bool use_advice = true;
  bool auto_fire_dir = true;
  double reaction_time = 0.25;
  double _react_time = 0;

  final move_dir = Vector2.zero();
  final fire_dir = Vector2.zero();

  final _temp_move = Vector2.zero();
  final _check_pos = Vector2.zero();
  final _last_free = Vector2.zero();
  final _temp_bounds = MutableRectangle<double>(0, 0, 0, 0);

  @override
  FutureOr<void> onLoad() async {
    if (!my_properties.keys.any((it) => it == 'spawn_late')) {
      await my_prop.add(SpawnWhenVisible());
    }
    active_weapon = WeaponType.by_name(my_properties['weapon']);
    return super.onLoad();
  }

  @override
  void post_mount() {
    for (final it in my_prop.enemy_behaviors) {
      it.attach(this);
    }
    if (my_prop.movement_modes.isEmpty) {
      my_prop.add(MovementDownOnly()..attach(this));
    }

    my_prop.add(AutoAnimation(sprites)..attach(this));

    stationary = my_prop.movement_modes.singleOrNull is MovementStationary;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // TODO: How to do this properly? From outside?
    (parent as LevelProp).anchor = Anchor(0.5, 0.8);

    if (!active) return;

    if (_react_time <= 0) {
      _offer_reaction();
      _react_time = reaction_time + rng.nextDoublePM(reaction_time / 4);
    } else {
      _react_time -= min(_react_time, dt);
    }

    if (use_advice) {
      final advice = level.advice_for(my_prop.position);
      if (advice != null) move_dir.setFrom(advice);
      _try_move(dt);
    }

    _temp_move.setFrom(move_dir);
    _temp_move.scale(configuration.enemy_move_speed * dt);
    my_prop.position.add(_temp_move);
    my_prop.priority = my_prop.position.y.toInt() + (stationary ? 16 : 0);
    my_prop.update_bounds();

    if (auto_fire_dir && !move_dir.isZero()) fire_dir.setFrom(move_dir);
  }

  void _offer_reaction() {
    for (final it in my_prop.enemy_behaviors) {
      it.offer_reaction();
    }
  }

  void _try_move(double dt) {
    move_dir.normalize();

    _temp_move.setFrom(move_dir);
    _temp_move.scale(configuration.enemy_move_speed * dt);
    _check_pos.setFrom(my_prop.position);
    _check_pos.add(_temp_move);

    _temp_bounds.left = _check_pos.x - 7;
    _temp_bounds.top = _check_pos.y - 7;
    _temp_bounds.width = 14;
    _temp_bounds.height = my_prop.height * 0.125;

    for (final it in entities.obstacles) {
      if (it.is_blocked_for_walking(_temp_bounds, enemy: true)) {
        if (move_dir.x != 0 && move_dir.y != 0) {
          // For diagonal movement, try to find an alternative path
          final remember_x = move_dir.x;
          final remember_y = move_dir.y;

          // First try horizontal movement
          move_dir.y = 0;
          move_dir.x = remember_x.sign;
          _try_move(dt);

          // If horizontal movement fails, try vertical movement
          if (move_dir.isZero()) {
            move_dir.x = 0;
            move_dir.y = remember_y.sign;
            _try_move(dt);
          }

          return;
        }

        move_dir.setZero();
        my_prop.position.setFrom(_last_free);
        return;
      }
    }

    _last_free.setFrom(_check_pos);
  }
}
