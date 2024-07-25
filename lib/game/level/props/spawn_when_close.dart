import 'package:commando24/game/game_context.dart';
import 'package:flame/components.dart';

import 'level_prop_extensions.dart';
import 'proximity_sensor.dart';

class SpawnWhenClose extends Component {
  @override
  void onMount() {
    super.onMount();
    removeFromParent();
    _replace_with_proximity_sensor();
  }

  void _replace_with_proximity_sensor() {
    final it = my_prop;
    model.add(ProximitySensor(
      center: it.center,
      radius: 32,
      when_triggered: () => model.add(it),
    ));
    it.removeFromParent();
  }
}
