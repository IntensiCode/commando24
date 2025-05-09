import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/level/distance_field.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/mutable.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class PathFinder extends Component with AutoDispose {
  static const tile_size = 16.0;
  static const grid_size = 8.0;
  static const half_size = grid_size / 2;

  DistanceField? _distances;

  var _snapshot = <LevelObject>{};

  final _temp_rect = MutableRectangle<double>(0, 0, 0, 0);

  @override
  void onMount() {
    super.onMount();
    onMessage<LevelDataAvailable>((it) => _init(it.map));
  }

  double _to_x(int col) => col * grid_size + half_size;

  // Because the camera moves "up" along the negative y axis, this hack:
  double _to_y(int row) => game_height - grid_size - row * grid_size + half_size;

  int _to_col(double x) => x ~/ grid_size;

  // Because the camera moves "up" along the negative y axis, this hack:
  int _to_row(double y) => (game_height - grid_size + half_size - y) ~/ grid_size;

  void _init(TiledMap map) {
    bool is_blocked(int col, int row) {
      _temp_rect.left = _to_x(col) - half_size + 0.5;
      _temp_rect.top = _to_y(row) - half_size + 0.5;
      _temp_rect.width = grid_size - 1;
      _temp_rect.height = grid_size - 1;
      return _snapshot.firstWhereOrNull((it) => it.is_blocked_for_walking(_temp_rect)) != null;
    }

    final cols = map.width * tile_size ~/ grid_size;
    final rows = map.height * tile_size ~/ grid_size;
    log_info('init distance field: $cols x $rows');
    _distances = DistanceField(cols: cols, rows: rows, is_blocked: is_blocked);
  }

  final debug_paths = <List<Vector2>>{};

  void find_path_to_player(LevelProp from, List<Vector2> out_segment) {
    debug_paths.add(out_segment);

    final col = _to_col(from.position.x);
    final row = _to_row(from.position.y);

    _distances?.find_path_to_player(col, row, out_segment);

    for (final it in out_segment) {
      if (it.isNaN) continue;
      it.x = _to_x(it.x.toInt());
      it.y = _to_y(it.y.toInt());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update snapshot of obstacles TODO: Optimize - only when something changed
    _snapshot = entities.obstacles.toSet();

    // Notify distance field if player moved
    final col = _to_col(player.position.x);
    final row = _to_row(player.position.y);
    _distances?.on_position_changed(col, row);

    // Update distance field
    _distances?.update();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final df = _distances;
    if (df == null) return;

    final rect = game.camera.visibleWorldRect;

    for (var y = 0; y < df.rows; ++y) {
      if (rect.top > _to_y(y) || rect.bottom < _to_y(y)) continue;

      for (var x = 0; x < df.cols; ++x) {
        final d = df.distance[y][x];
        _pos.dx = _to_x(x);
        _pos.dy = _to_y(y);
        if (d == -1) continue;

        final l = (d / 40).clamp(0.0, 1.0);
        final c = d == -1 ? black : Color.lerp(green, red, l)!;
        _paint.color = c.withValues(alpha: 0.5);
        canvas.drawCircle(_pos, grid_size / 3, _paint);

        if (_is_on_path(x, y)) {
          _paint.color = black;
          canvas.drawCircle(_pos, grid_size / 3, _paint);
        }
      }
    }
  }

  bool _is_on_path(int x, int y) {
    for (final it in debug_paths) {
      for (final pos in it) {
        if (pos.isNaN) continue;
        if (_to_col(pos.x) == x && _to_row(pos.y) == y) return true;
      }
    }
    return false;
  }

  final _pos = MutableOffset(0, 0);
  final _paint = pixel_paint();
}
