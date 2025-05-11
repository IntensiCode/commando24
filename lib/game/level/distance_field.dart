import 'dart:collection';

import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

/// Closure type for checking if a tile is blocked.
typedef IsTileBlocked = bool Function(int col, int row);

/// Reverse Dijkstra distance field pathfinder.
class DistanceField {
  static int steps_per_update = 500;
  static int max_distance = 100;

  final int cols;
  final int rows;
  final IsTileBlocked is_blocked;

  late List<List<int>> distance;
  late List<List<int>> _next_distance;
  late final Queue<List<int>> _queue;

  (int, int)? computing;
  (int, int)? pending;
  (int, int)? computed;

  DistanceField({
    required this.cols,
    required this.rows,
    required this.is_blocked,
  }) {
    distance = List.generate(rows, (_) => List.filled(cols, -1));
    _next_distance = List.generate(rows, (_) => List.filled(cols, -1));
    _queue = Queue<List<int>>();
  }

  void on_position_changed(int col, int row) {
    final it = (col, row);
    if (pending == it) return;
    pending = it;
    log_verbose('pending changed: $pending');
  }

  /// Call this every frame to incrementally compute the distance field.
  void update() {
    if (computing == null && pending != null) {
      _start_compute();
    }
    if (computing != null) {
      _continue_compute();
    }
  }

  bool _in_bounds(int col, int row) => col >= 0 && col < cols && row >= 0 && row < rows;

  void _continue_compute() {
    final dx = const [0, -1, 1, 0];
    final dy = const [-1, 0, 0, 1];

    int steps = steps_per_update;
    while (_queue.isNotEmpty && steps-- > 0) {
      final curr = _queue.removeFirst();
      final x = curr[0], y = curr[1];
      final dist = _next_distance[y][x];
      for (int d = 0; d < 4; ++d) {
        final nx = x + dx[d];
        final ny = y + dy[d];
        if (_in_bounds(nx, ny) && _next_distance[ny][nx] == -1 && !is_blocked(nx, ny)) {
          _next_distance[ny][nx] = dist + 1;
          if (dist < max_distance) _queue.addLast([nx, ny]);
        }
      }
    }

    // If finished, swap buffers:
    if (_queue.isEmpty) {
      final tmp = distance;
      distance = _next_distance;
      _next_distance = tmp;

      computed = computing;
      computing = null;
      _queue.clear();
    }
  }

  void _start_compute() {
    final (col, row) = pending!;

    // Reset next buffer
    for (final row in _next_distance) {
      row.fill(-1);
    }

    _queue.clear();
    if (_in_bounds(col, row)) {
      _next_distance[row][col] = 0;
      _queue.addLast([col, row]);
    }

    computing = (col, row);
  }

  /// Returns the next up to 5 tile positions (as Vector2) from `from` towards the player.
  void find_path_to_player(int col, int row, List<Vector2> out_segment) {
    for (final it in out_segment) {
      it.setAll(double.nan);
    }

    if (!_in_bounds(col, row)) return;

    int x = col, y = row;
    for (int step = 0; step < out_segment.length; ++step) {
      int best = distance[y][x];
      if (best == -1) best = 100000;

      int? next_x, next_y;
      for (final dir in const [(0, -1), (-1, 0), (1, 0), (0, 1)]) {
        final nx = x + dir.$1;
        final ny = y + dir.$2;
        if (ny < 0 || ny > rows || nx < 0 || nx > cols) continue;
        // log_info('check $nx, $ny dist: ${distance[ny][nx]}');
        if (_in_bounds(nx, ny) && distance[ny][nx] >= 0 && distance[ny][nx] < best) {
          best = distance[ny][nx];
          next_x = nx;
          next_y = ny;
        }
      }
      if (next_x == null || next_y == null) break;

      x = next_x;
      y = next_y;
      out_segment[step].setValues(x.toDouble(), y.toDouble());

      if (distance[y][x] == 0) break; // reached player
    }
  }
}
