import 'package:commando24/game/explosions.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class Explosive extends Component with GameContext {
  @override
  void onMount() {
    super.onMount();
    my_prop.when_destroyed.add(() => explosions.spawn_explosion_for(my_prop));
  }
}
