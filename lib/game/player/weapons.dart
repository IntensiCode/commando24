import 'dart:async';

import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/player/assault_rifle.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/bazooka.dart';
import 'package:commando24/game/player/flame_thrower.dart';
import 'package:commando24/game/player/machine_gun.dart';
import 'package:commando24/game/player/player.dart';
import 'package:commando24/game/player/shotgun.dart';
import 'package:commando24/game/player/sub_machine_gun.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

extension GameContextExtensions on GameContext {
  Weapons get weapons => cache.putIfAbsent('weapons', () => Weapons());
}

class Weapons extends Component with AutoDispose, GameContext, HasAutoDisposeShortcuts {
  final weapons = <WeaponType, BaseWeapon>{};

  @override
  onLoad() {
    if (weapons.isEmpty) {
      final SpriteSheet sprites = atlas.sheetIWH('tileset', 16, 16);
      weapons[WeaponType.assault_rifle] = added(AssaultRifle.make(sprites));
      weapons[WeaponType.bazooka] = added(Bazooka.make(sprites));
      weapons[WeaponType.flame_thrower] = added(FlameThrower.make(sprites));
      weapons[WeaponType.machine_gun] = added(MachineGun.make(sprites));
      weapons[WeaponType.smg] = added(SubMachineGun.make(sprites));
      weapons[WeaponType.shotgun] = added(Shotgun.make(sprites));
    }
    return super.onLoad();
  }

  @override
  Future onMount() async {
    super.onMount();

    player.active_weapon ??= weapons[WeaponType.assault_rifle];

    on_message<Collected>((it) => _handle_weapons(it));
    on_message<EnterRound>((_) => _reset(reset_weapons: false));
    on_message<WeaponBonus>((it) => _switch_weapon(it.type));
    on_message<WeaponEmpty>((_) => _switch_weapon(WeaponType.assault_rifle));
    //...

    on_key('1', () => _switch_weapon(WeaponType.assault_rifle));
    on_key('2', () => _switch_weapon(WeaponType.bazooka));
    on_key('3', () => _switch_weapon(WeaponType.flame_thrower));
    on_key('4', () => _switch_weapon(WeaponType.machine_gun));
    on_key('5', () => _switch_weapon(WeaponType.smg));
    on_key('6', () => _switch_weapon(WeaponType.shotgun));
  }

  void _handle_weapons(Collected it) {
    final type = WeaponType.by_name(it.consumable.properties['type']);
    if (type == null || type == WeaponType.grenades) return;
    player.active_weapon = weapons[type];
    player.active_weapon?.ammo += type.pickup_ammo;
  }

  void _reset({bool reset_weapons = false}) {
    if (reset_weapons) {
      for (final it in weapons.values) {
        it.ammo = 0;
      }
    }
  }

  void _switch_weapon(WeaponType type) {
    final weapon = weapons[type];
    if (weapon == null) return;

    if (weapon.ammo == 0 && !dev) {
      soundboard.play(Sound.empty_click);
    } else {
      if (dev) weapon.ammo += 50;
      player.active_weapon = weapon;
      send_message(WeaponSwitched(type));
    }
  }
}
