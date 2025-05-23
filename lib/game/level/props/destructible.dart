import 'package:commando24/game/decals.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

class Destructible extends Component with GameContext {
  late final double _hit_points;

  late double _remaining_hits;

  double get damage_percent => (100 - _remaining_hits / _hit_points * 100).clamp(0, 100);

  void on_hit(WeaponType type) {
    if (_remaining_hits <= 0) return;

    var damage = (type.projectile_damage ?? 0);
    damage += (type.blast_damage ?? 0) * configuration.projectile_hits_per_grenade;
    if (damage == 0) return;

    _remaining_hits -= damage;
    if (_remaining_hits <= 0) {
      _remaining_hits = 0;
      decals.spawn_for(my_prop);
      my_prop.removeFromParent();
      my_prop.when_destroyed.forEach((it) => it());
      my_prop.when_destroyed.clear();
      my_prop.when_hit.clear();
    } else {
      my_prop.when_hit.forEach((it) => it());
    }
  }

  @override
  void onMount() {
    super.onMount();

    var hit_points = (my_properties['grenade_hits'] as int? ?? 0) * configuration.projectile_hits_per_grenade;
    if (hit_points == 0) {
      hit_points = my_properties['hits'] as int? ?? 0;
    } else {
      if (my_properties['hits'] != null) {
        throw 'cannot have both hits and grenade_hits';
      }
    }
    if (hit_points == 0) {
      log_warn('default hit points for $parent');
      hit_points = 1;
    }

    _hit_points = hit_points.toDouble();
    _remaining_hits = hit_points.toDouble();
  }
}
