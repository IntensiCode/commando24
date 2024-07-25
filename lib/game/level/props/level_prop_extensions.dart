import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/level/props/flammable.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:flame/components.dart';

import 'consumable.dart';
import 'destructible.dart';

extension ComponentExtensions on Component {
  LevelProp get my_prop => parent as LevelProp;

  Map<String, dynamic> get my_properties => my_prop.properties;

  bool get is_consumable => children.any((it) => it is Consumable);

  bool get is_destructible => children.any((it) => it is Destructible);

  bool get is_flammable => children.any((it) => it is Flammable);
}

extension LevelObjectExtensions on LevelObject {
  bool get starts_burning => properties['burns'] == true;

  double get damage_percent => destructible.damage_percent;

  Destructible get destructible => children.whereType<Destructible>().single;

  Flammable? get flammable => children.whereType<Flammable>().singleOrNull;
}
