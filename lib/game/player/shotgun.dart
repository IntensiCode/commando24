import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/projectile.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/util/random.dart';
import 'package:flame/sprite.dart';
import 'package:kart/kart.dart';

class Shotgun extends BaseWeapon {
  static Shotgun make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 44, to: 44);
    return Shotgun._(animation);
  }

  Shotgun._(SpriteAnimation animation)
      : super(
          WeaponType.shotgun,
          animation,
          Sound.shot_shotgun_real,
          fire_rate: configuration.shotgun_fire_rate,
          spread: configuration.shotgun_spread,
        ) {
    projectile_behaviors.add(RandomizeVelocity());
  }

  @override
  void on_fire(double dt, {bool sound = true, bool show_firing = true}) {
    repeat(10, (it) => super.on_fire(dt, sound: it == 0));
    ammo += 8;
  }
}

class RandomizeVelocity extends ProjectileBehavior {
  @override
  void init(Projectile projectile) {
    projectile.velocity.scale(rng.nextDoubleLimit(0.1) + 1);
  }
}
