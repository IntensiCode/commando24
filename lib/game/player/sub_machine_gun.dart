import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:flame/sprite.dart';

class SubMachineGun extends BaseWeapon {
  static SubMachineGun make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 46, to: 46);
    return SubMachineGun._(animation);
  }

  SubMachineGun._(SpriteAnimation animation)
      : super(
          WeaponType.smg,
          animation,
          Sound.shot_smg,
          fire_rate: configuration.smg_fire_rate,
          spread: configuration.smg_spread,
        );
}
