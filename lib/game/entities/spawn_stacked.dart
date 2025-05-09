import 'package:commando24/core/common.dart';
import 'package:commando24/game/entities/spawn_mode.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

class SpawnStacked extends Component {
  final pending = <SpawnMode>[];

  static int spawn_interval = 1000;
  static int last_spawn = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (pending.isEmpty) {
      pending.addAll(my_prop.children.whereType<SpawnMode>());
      my_prop.removeAll(pending);
      if (pending.isNotEmpty) return;
      if (dev) throw 'no spawns on $my_prop';
      log_error('no spawns on $my_prop');
      removeFromParent();
    } else {
      final which = pending.where((it) => it.should_spawn(my_prop));
      if (which.isEmpty) return;

      final now = DateTime.timestamp().millisecondsSinceEpoch;
      if (now < last_spawn + spawn_interval) return;

      last_spawn = now;

      log_info('activate ${which.first}');
      my_prop.add(which.first);
      pending.remove(which.first);
      if (pending.isEmpty) removeFromParent();
    }
  }
}
