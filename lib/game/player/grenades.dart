import 'dart:async';

import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/explosions.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/bazooka.dart';
import 'package:commando24/game/player/projectile.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/input/game_keys.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';

extension GameContextExtensions on GameContext {
  Grenades get grenades => cache.putIfAbsent('grenades', () => Grenades.make());
}

class Grenades extends BaseWeapon with HasAutoDisposeShortcuts {
  static Grenades make() {
    final sprites = atlas.sheetIWH('tileset', 16, 16);
    final animation = sprites.createAnimation(row: 21, stepTime: 0.2, from: 41, to: 48, loop: false);
    return Grenades._(animation);
  }

  Grenades._(SpriteAnimation animation)
      : super(
          WeaponType.grenades,
          animation,
          Sound.empty_click,
          fire_rate: configuration.grenades_fire_rate,
          spread: configuration.grenades_spread,
          projectile_speed: 75,
        ) {
    ammo = 3;

    weapon_behaviors.removeWhere((it) => it is FireRateOnGameKey);
    weapon_behaviors.removeWhere((it) => it is PlayerRelativeSpeed);
    weapon_behaviors.add(PlayerRelativeSpeed(add_relative: false));
    weapon_behaviors.add(FireRateOnGameKey(GameKey.b_button, show_firing: false));

    projectile_behaviors.clear();
    projectile_behaviors.add(RecycleOutOfBounds());
    projectile_behaviors.add(JumpGrenade());
    projectile_behaviors.add(ExplodeOnImpact());
  }

  @override
  bool get active => true;

  @override
  Future onMount() async {
    super.onMount();

    on_message<Collected>((it) => _handle_pickup(it));
    on_message<EnterRound>((_) => _reset(reset_ammo: false));

    if (dev) on_key('0', () => ammo += 10);
  }

  void _handle_pickup(Collected it) {
    final type = WeaponType.by_name(it.consumable.properties['type']);
    if (type == null || type != WeaponType.grenades) return;
    ammo += type.pickup_ammo;
  }

  void _reset({bool reset_ammo = false}) {
    if (reset_ammo) ammo = 3;
  }

  @override
  void on_fire(double dt, {bool sound = true, bool show_firing = true}) {
    super.on_fire(dt, sound: sound, show_firing: show_firing);
    keys.consume(GameKey.b_button);
  }
}

class JumpGrenade extends ProjectileBehavior {
  static final _hit = RecycleOnTargetHit();

  @override
  void init(Projectile projectile) => projectile._init();

  @override
  void update(Projectile projectile, double dt) => projectile._update(dt, _hit);
}

final _temp_pos = Vector2.zero();

extension on Projectile {
  void _init() {
    base_x = position.x;
    base_y = position.y;
    base_z = 0;
    active = false;
    speed_z = 250;
    animationTicker?.reset();
  }

  void _update(double dt, RecycleOnTargetHit hit) {
    speed_z -= 500 * dt;

    base_x += velocity.x * dt;
    base_y += velocity.y * dt;
    base_z += speed_z * dt;
    if (base_z < 0) {
      active = true;

      speed_z = -speed_z;
      base_z += speed_z * dt;
      speed_z *= 0.6;
      if (speed_z < 75) {
        _temp_pos.setFrom(position);
        _temp_pos.y += 16;
        explosions.spawn_big_explosion(position: _temp_pos);
        recycle();
      }
    }

    position.setValues(base_x, base_y);
    position.y -= base_z;
    priority = (position.y + 10 + base_z).toInt();

    if (active) hit.update(this, dt);
  }

  bool get active => data['active'] as bool;

  double get base_x => data['base_x'] as double;

  double get base_y => data['base_y'] as double;

  double get base_z => data['base_z'] as double;

  double get speed_z => data['speed_z'] as double;

  set base_x(double value) => data['base_x'] = value;

  set base_y(double value) => data['base_y'] = value;

  set base_z(double value) => data['base_z'] = value;

  set active(bool value) => data['active'] = value;

  set speed_z(double value) => data['speed_z'] = value;
}
