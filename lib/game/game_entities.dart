import 'dart:async';

import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/level/level_tiles.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class GameEntities extends Component {
  GameEntities() {
    entities = this;
  }

  final solids = <StackedTile>[];
  final consumables = <LevelProp>[];
  final destructibles = <LevelProp>[];
  final flammables = <LevelProp>[];

  Iterable<LevelObject> get obstacles sync* {
    yield* solids;
    yield* destructibles;
  }

  @override
  FutureOr<void> add(Component component) {
    if (component is StackedTile) {
      _manage(component, solids);
    }
    if (component is LevelProp) {
      if (component.is_consumable) _manage(component, consumables);
      if (component.is_destructible) _manage(component, destructibles);
      if (component.is_flammable) _manage(component, flammables);
    }
    return super.add(component);
  }

  void _manage<T extends LevelObject>(T prop, List<T> list) {
    if (prop.isMounted) {
      list.add(prop);
    } else {
      prop.mounted.then((_) => list.add(prop));
    }
    prop.removed.then((_) => list.remove(prop));
  }
}
