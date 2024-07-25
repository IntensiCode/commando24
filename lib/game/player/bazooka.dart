import 'package:collection/collection.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/player/base_weapon.dart';
import 'package:commando24/game/player/projectile.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/game_keys.dart';
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
        );

  @override
  void on_fire(double dt, {bool sound = true}) {
    super.on_fire(dt, sound: sound);
    keys.consume(GameKey.fire1);
  }

  @override
  void update_projectile(double dt, Projectile projectile) {
    super.update_projectile(dt, projectile);
    if (projectile.children.none((it) => it is SmokeTrail)) {
      projectile.add(SmokeTrail());
    }
    if (projectile.children.none((it) => it is ExplodeOnImpact)) {
      projectile.add(ExplodeOnImpact());
    }
  }
}

class ExplodeOnImpact extends Component {
  static final _temp_pos = Vector2.zero();

  @override
  void onMount() {
    super.onMount();
    final it = parent as Projectile;
    it.removed.then((_) {
      _temp_pos.setFrom(it.position);
      _temp_pos.y += 16;
      model.explosions.spawn_big_explosion(position: _temp_pos);
    });
  }
}

class SmokeTrail extends Component {
  static const emit_interval = 0.05;

  late Projectile _projectile;

  double _emit_time = 0;

  @override
  void onMount() {
    super.onMount();
    _projectile = parent as Projectile;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _emit_time += dt;
    if (_emit_time < emit_interval) return;
    _emit_time -= emit_interval + rng.nextDoubleLimit(emit_interval / 3);
    model.particles.spawn_smoke(_projectile.position, rng.nextDoubleLimit(4));
  }
}
