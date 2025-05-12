import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/level/distance_field.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/player/player.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/mutable.dart';
import 'package:commando24/util/on_message.dart';
import 'package:commando24/util/performance.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

bool debug_path_finder = dev;

extension GameContextExtensions on GameContext {
  PathFinder get path_finder => cache.putIfAbsent('path_finder', () => PathFinder());
}

class PathFinder extends Component with AutoDispose, GameContext {
  static const tile_size = 16.0;
  static const grid_size = 8.0;
  static const half_size = grid_size / 2;

  DistanceField? _distances;

  late List<List<bool>> _solids;
  late List<List<int>> _destructibles;
  final _snapshot = <LevelProp, MutableRectangle<double>>{};
  final _temp_rect = MutableRectangle<double>(0, 0, 0, 0);

  @override
  void onMount() {
    super.onMount();
    on_message<LevelDataAvailable>((it) => _init(it.map));
    on_message<LevelReady>((it) => _init_solids());
  }

  double _to_x(int col) => col * grid_size + half_size;

  // Because the camera moves "up" along the negative y axis, this hack:
  double _to_y(int row) => game_height - grid_size - row * grid_size + half_size;

  int _to_col(double x) => x ~/ grid_size;

  // Because the camera moves "up" along the negative y axis, this hack:
  int _to_row(double y) => (game_height - grid_size + half_size - y) ~/ grid_size;

  bool is_blocked(int col, int row) {
    if (_solids[row][col]) return true;
    if (_destructibles[row][col] > 0) return true;
    return false;
  }

  bool _is_blocked(Set<LevelObject> objects, int col, int row) {
    _temp_rect.left = _to_x(col) - half_size + 0.5;
    _temp_rect.top = _to_y(row) - half_size + 0.5;
    _temp_rect.width = grid_size - 1;
    _temp_rect.height = grid_size - 1;
    return objects.firstWhereOrNull((it) => it.is_blocked_for_walking(_temp_rect)) != null;
  }

  void _init(TiledMap map) {
    final cols = map.width * tile_size ~/ grid_size;
    final rows = map.height * tile_size ~/ grid_size;
    log_info('init distance field: $cols x $rows');
    _distances = DistanceField(cols: cols, rows: rows, is_blocked: is_blocked);
    _solids = List.generate(rows, (_) => List.generate(cols, (_) => false, growable: false), growable: false);
    _destructibles = List.generate(rows, (_) => List.generate(cols, (_) => 0, growable: false), growable: false);
  }

  void _init_blocked(List<List<bool>> target, Set<LevelObject> objects) {
    for (int row = 0; row < target.length; ++row) {
      for (int col = 0; col < target[0].length; ++col) {
        target[row][col] = _is_blocked(objects, col, row);
      }
    }
  }

  void _init_solids() => _init_blocked(_solids, entities.solids.toSet());

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
    _update_destructibles();

    // Notify distance field if player moved
    final col = _to_col(player.position.x);
    final row = _to_row(player.position.y);
    _distances?.on_position_changed(col, row);

    // Update distance field
    timed('update distance field', () => _distances?.update());
  }

  Iterable<(int col, int row)> _blocked_for(Rectangle<double> rect) sync* {
    final cl = _to_col(rect.left + 0.5);
    final cr = _to_col(rect.left + rect.width - 0.5);
    final rt = _to_row(rect.top - half_size + 0.5);
    final rb = _to_row(rect.top + rect.height - half_size - 0.5);
    for (int y = rb; y <= rt; ++y) {
      for (int x = cl; x <= cr; ++x) {
        yield (x, y);
      }
    }
  }

  bool _unchanged(Rectangle<double> a, Rectangle<double> b) =>
      a.left == b.left && a.top == b.top && a.width == b.width && a.height == b.height;

  void _update_blocked(Rectangle<double> rect, int delta) {
    for (final (c, r) in _blocked_for(rect)) {
      if (c < 0 || r < 0 || c >= _destructibles[0].length || r >= _destructibles.length) continue;
      _destructibles[r][c] += delta;
    }
  }

  void _update_destructibles() {
    timed('update destructibles ${_snapshot.length}', () {
      // Excluding enemies to not have them block each other:
      final snapshot = entities.destructibles.where((it) => !it.is_enemy).toSet();

      for (final it in _snapshot.keys) {
        if (snapshot.contains(it)) continue;
        _update_blocked(_snapshot[it]!, -1);
      }

      for (final it in snapshot) {
        final r = it.hit_bounds;
        final s = _snapshot[it];

        if (s != null) {
          if (_unchanged(s, r)) continue;
          _update_blocked(s, -1);
        }
        _update_blocked(r, 1);

        _snapshot[it] ??= MutableRectangle<double>(0, 0, 0, 0);
        _snapshot[it]!.left = r.left;
        _snapshot[it]!.top = r.top;
        _snapshot[it]!.width = r.width;
        _snapshot[it]!.height = r.height;
      }
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!debug_path_finder) return;

    final df = _distances;
    if (df == null) return;

    final rect = game.camera.visibleWorldRect;

    for (var y = 0; y < df.rows; ++y) {
      if (rect.top > _to_y(y) || rect.bottom < _to_y(y)) continue;

      for (var x = 0; x < df.cols; ++x) {
        final d = df.distance[y][x];
        _pos.dx = _to_x(x);
        _pos.dy = _to_y(y);
        if (d == -1) {
          _paint.color = black;
          canvas.drawCircle(_pos, 1.0, _paint);
          continue;
        }

        final l = (d / 40).clamp(0.0, 1.0);
        final c = d == -1 ? black : Color.lerp(green, red, l)!;
        _paint.color = c.withValues(alpha: 0.5);
        canvas.drawCircle(_pos, grid_size / 3, _paint);

        if (_is_on_path(x, y)) {
          _paint.color = blue.withValues(alpha: 0.75);
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
  final _paint = pixel_paint()
    ..strokeWidth = 1.25
    ..style = PaintingStyle.stroke;
}
