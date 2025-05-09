import 'dart:ui';

import 'package:commando24/core/common.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class LevelProp extends SpriteComponent with HasVisibility, LevelObject, TapCallbacks {
  LevelProp({
    required super.sprite,
    required Paint paint,
    required super.position,
    required super.priority,
    super.children,
  }) : super(anchor: Anchor.bottomCenter) {
    level_paint = paint;
    position.x += width / 2;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (dev) log_info(this);
  }

  @override
  String toString() => '''
${super.toString()}
- traits: $children
- props: $properties
    ''';
}
