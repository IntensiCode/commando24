// ignore_for_file: avoid_print

import 'package:commando24/game/level/distance_field.dart';
import 'package:flame/components.dart';
import 'package:test/test.dart';

String _snapshot(DistanceField df, [List<Vector2>? path]) {
  final cols = df.distance.isNotEmpty ? df.distance[0].length : 0;
  final rows = df.distance.length;
  final buffer = StringBuffer();

  // Header row: column indices
  buffer.write('   ');
  for (var col = 0; col < cols; col++) {
    buffer.write(col % 10);
  }
  buffer.writeln();

  // Top boundary
  buffer.write('  +');
  buffer.write('-' * cols);
  buffer.writeln();

  // Rows with row index and left boundary
  for (var row = 0; row < rows; row++) {
    buffer.write(row.toString().padLeft(2));
    buffer.write('|');
    for (var col = 0; col < cols; col++) {
      final it = df.distance[row][col];
      if (path?.contains(Vector2(col.toDouble(), row.toDouble())) == true) {
        buffer.write('X');
      } else if (it == -1) {
        buffer.write(' ');
      } else if (it >= 0 && it <= 9) {
        buffer.write(it.toString());
      } else if (it >= 10 && it <= 35) {
        buffer.write(String.fromCharCode(it + 'A'.codeUnitAt(0) - 10));
      } else {
        buffer.write('?');
      }
    }
    buffer.writeln();
  }

  return buffer.toString();
}

DistanceField _create_sut({int cols = 8, int rows = 8, required List<(int, int)> blocked}) =>
    DistanceField(cols: cols, rows: rows, is_blocked: (col, row) => blocked.contains((col, row)));

void main() {
  test('Build distance field', () {
    //given
    final df = _create_sut(blocked: [(3, 3), (3, 4), (4, 3), (4, 4)]);

    //when
    df.on_position_changed(1, 1);
    df.update();
    print(_snapshot(df));

    //then
    expect(df.distance[0][0], 2);
    expect(df.distance[1][0], 1);
    expect(df.distance[0][1], 1);
    expect(df.distance[1][1], 0);
    expect(df.distance[3][3], -1);
    expect(df.distance[3][4], -1);
    expect(df.distance[4][3], -1);
    expect(df.distance[4][4], -1);
  });

  test('Find direct way towards player', () {
    //given
    final df = _create_sut(blocked: [(3, 3), (3, 4), (4, 3), (4, 4)]);
    final actual = List.generate(5, (_) => Vector2.all(double.nan));
    df.on_position_changed(1, 1);
    df.update();

    //when
    df.find_path_to_player(5, 1, actual);
    print(_snapshot(df, actual));

    //then
    expect(actual[0], Vector2(4.0, 1.0));
    expect(actual[1], Vector2(3.0, 1.0));
    expect(actual[2], Vector2(2.0, 1.0));
    expect(actual[3], Vector2(1.0, 1.0));
    expect(actual[4].x, isNaN);
    expect(actual[4].y, isNaN);
  });

  test('Find way towards player', () {
    //given
    final df = _create_sut(blocked: [(3, 3), (3, 4), (4, 3), (4, 4)]);
    final actual = List.generate(5, (_) => Vector2.all(double.nan));
    df.on_position_changed(1, 1);
    df.update();

    //when
    df.find_path_to_player(5, 5, actual);
    print(_snapshot(df, actual));

    //then
    expect(actual[0], Vector2(5.0, 4.0));
    expect(actual[1], Vector2(5.0, 3.0));
    expect(actual[2], Vector2(5.0, 2.0));
    expect(actual[3], Vector2(5.0, 1.0));
    expect(actual[4], Vector2(4.0, 1.0));
  });
}
