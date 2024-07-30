import 'package:commando24/game/level/props/level_prop.dart';
import 'package:flame/components.dart';

mixin SpawnMode on Component {
  bool should_spawn(LevelProp prop);
}
