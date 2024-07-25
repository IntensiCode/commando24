import 'dart:ui';

import 'package:flame/components.dart';

import '../level_object.dart';

class LevelProp extends SpriteComponent with HasVisibility, LevelObject {
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
  String toString() => '$properties with $children at $position';
}
