import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:flame/sprite.dart';

class MachineGun extends BaseWeapon {
  static MachineGun make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 42, to: 42);
    return MachineGun._(animation);
  }

  MachineGun._(SpriteAnimation animation)
      : super(
          WeaponType.machine_gun,
          animation,
          Sound.shot_machine_gun_real,
          fire_rate: configuration.machine_gun_fire_rate,
          spread: configuration.machine_gun_spread,
        );
}
