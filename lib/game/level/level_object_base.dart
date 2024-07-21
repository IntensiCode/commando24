import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/common.dart';
import '../../util/extensions.dart';
import '../../util/random.dart';
import '../game_context.dart';
import 'level_state.dart';

mixin LevelObjectBase on SpriteComponent, HasVisibility {
  final _our_bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);
  final _player_bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);

  late final Paint level_paint;

  double? override_width;
  double? override_height;

  Map<String, Object> properties = {};

  int _frame_check = rng.nextInt(10);

  double get _width => override_width ?? width;

  double get _height => override_height ?? height;

  bool dirty = true;

  @override
  bool get isVisible {
    final visible = game.camera.visibleWorldRect;
    return position.y < visible.bottom + height && position.y > visible.top;
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (level.state) {
      case LevelState.waiting:
        return;
      case LevelState.appearing:
        paint = level_paint;
      case LevelState.active:
        if (paint == level_paint) {
          paint = pixel_paint();
        }
        _update(dt);
      case LevelState.defeated:
        return;
    }
  }

  void _update(double dt) {
    if (++_frame_check < 10) return;
    _frame_check = 0;

    if (dirty) {
      _our_bounds.left = position.x - _width / 2;
      _our_bounds.top = position.y - _height;
      _our_bounds.width = _width;
      _our_bounds.height = _height;
      dirty = false;
    }

    _player_bounds.left = player.position.x - player.width / 2;
    _player_bounds.top = player.position.y - player.height * 0.8;
    _player_bounds.width = player.width;
    _player_bounds.height = player.height;

    // final player_close = _our_bounds.containsPoint(player.position.toPoint());
    final player_close = _our_bounds.intersects(_player_bounds);
    opacity = min(level_paint.opacity, player_close ? 0.5 : 1.0);
  }
}
