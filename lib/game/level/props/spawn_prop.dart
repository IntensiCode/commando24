import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/util/effects.dart';
import 'package:flame/components.dart';

class SpawnProp extends Component with GameContext {
  SpawnProp(this.consumable);

  final LevelProp consumable;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_removed.add(() {
      removeFromParent();
      entities.add(consumable);
      consumable.add(JumpEffect());
    });
  }
}
