import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/player/player_state.dart';
import 'package:commando24/game/player/projectile.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/component_recycler.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/keys.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/random.dart';
import 'package:flame/components.dart';

class BaseWeapon extends Component with AutoDispose, GameContext {
  BaseWeapon(
    this.type,
    this._animation,
    this._sound, {
    required this.fire_rate,
    required this.spread,
    this.projectile_speed = 250,
  });

  final WeaponType type;
  final SpriteAnimation _animation;
  final Sound _sound;

  final double fire_rate;
  final double spread;
  final double projectile_speed;

  late final Keys _keys;
  late final _recycler = ComponentRecycler(() => Projectile(type));

  final temp_pos = Vector2.zero();
  final temp_dir = Vector2.zero();
  final _north = Vector2(0, 1);

  int ammo = 0;

  double _fire_time = 0;

  @override
  void onMount() {
    super.onMount();
    _keys = keys;
  }

  @override
  void update(double dt) {
    if (ammo == 0) return;
    if (player.active_weapon != this) return;
    if (player.state != PlayerState.playing) return;
    super.update(dt);
    _on_fire_weapon(dt);
  }

  void _on_fire_weapon(double dt) {
    if (_keys.check(GameKey.fire1)) {
      if (_fire_time <= 0) {
        _fire_time = fire_rate;
        on_fire(dt);
      } else {
        _fire_time -= dt;
      }
    } else {
      _fire_time -= dt;
    }
  }

  void on_fire(double dt, {bool sound = true}) {
    if (ammo != -1 && --ammo == 0) sendMessage(WeaponEmpty(type));

    player.show_firing = fire_rate * 2;

    temp_pos.setFrom(player.position);
    temp_pos.y -= player.height / 3;

    temp_dir.setFrom(player.fire_dir);
    if (temp_dir.isZero()) temp_dir.setValues(0, -1);

    final projectile = _recycler.acquire();
    update_projectile(dt, projectile);
    model.add(projectile);

    if (sound) soundboard.play(_sound);
  }

  void update_projectile(double dt, Projectile projectile) {
    temp_dir.rotate(spread_rotation(dt));
    temp_dir.scale(player.move_dir.isZero() ? projectile_speed : projectile_speed + player.move_speed);
    projectile.angle = temp_dir.angleTo(_north);
    projectile.init(animation: _animation, position: temp_pos, velocity: temp_dir);
  }

  double spread_rotation(double dt) => rng.nextDoublePM(spread);
}
