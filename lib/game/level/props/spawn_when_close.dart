import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/level/props/proximity_sensor.dart';
import 'package:flame/components.dart';

class SpawnWhenClose extends Component with GameContext {
  @override
  void onMount() {
    super.onMount();
    removeFromParent();
    _replace_with_proximity_sensor();
  }

  void _replace_with_proximity_sensor() {
    final it = my_prop;
    entities.add(ProximitySensor(
      center: it.center,
      radius: 32,
      when_triggered: () => entities.add(it),
    ));
    it.removeFromParent();
  }
}
