import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/game/explosions.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/particles.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/projectile.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/input/game_keys.dart';
import 'package:commando24/util/random.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Bazooka extends BaseWeapon {
  static Bazooka make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 20, stepTime: 0.1, from: 42, to: 46);
    return Bazooka._(animation);
  }

  Bazooka._(SpriteAnimation animation)
      : super(
          WeaponType.bazooka,
          animation,
          Sound.shot_bazooka,
          fire_rate: configuration.bazooka_fire_rate,
          spread: configuration.bazooka_spread,
          projectile_speed: 150,
        ) {
    projectile_behaviors.add(SmokeTrail());
    projectile_behaviors.add(ExplodeOnImpact());
  }

  @override
  void on_fire(double dt, {bool sound = true, bool show_firing = true}) {
    super.on_fire(dt, sound: sound);
    keys.consume(GameKey.a_button);
  }
}

class ExplodeOnImpact extends ProjectileBehavior {
  static final _temp_pos = Vector2.zero();

  @override
  void target_hit(Projectile projectile, LevelObject target) {
    _temp_pos.setFrom(projectile.position);
    _temp_pos.y += 16;
    projectile.explosions.spawn_big_explosion(position: _temp_pos);
  }
}

class SmokeTrail extends ProjectileBehavior {
  static const emit_interval = 0.05;

  double _emit_time = 0;

  @override
  void update(Projectile projectile, double dt) {
    _emit_time += dt;
    if (_emit_time < emit_interval) return;
    _emit_time -= emit_interval + rng.nextDoubleLimit(emit_interval / 3);
    projectile.particles.spawn_smoke(projectile.position, rng.nextDoubleLimit(4));
  }
}
