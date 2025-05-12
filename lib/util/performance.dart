import 'dart:ui';

import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/foundation.dart';

const _reset_count = 1000000;

final _timings = <String, (int, Stopwatch)>{};

void timed(String hint, Function block) {
  final (count, delta) = _timings[hint] ??= (0, Stopwatch());
  delta.start();
  block();
  delta.stop();
  _timings[hint] = (count + 1, delta);
  if (count % 600 == 1) log_debug('$hint: ${delta.elapsedMicroseconds ~/ count} us');
  if (count % _reset_count == _reset_count - 1) _timings[hint] = (0, Stopwatch());
}

class Ticker {
  Ticker({int ticks = 60}) : step = 1.0 / ticks;

  final double step;

  double _remainder = 0;

  generateTicksFor(double dt, void Function(double) tick) {
    // for historic reasons i prefer constant ticks... ‾\_('')_/‾
    dt += _remainder;
    while (dt >= step) {
      tick(step);
      dt -= step;
    }
    _remainder = dt;
  }
}

class RenderTps<T extends TextRenderer> extends TextComponent with HasVisibility {
  RenderTps({
    super.position,
    super.size,
    super.scale,
    super.anchor,
  }) : super(priority: double.maxFinite.toInt()) {
    add(fpsComponent);
  }

  final fpsComponent = FpsComponent();

  @override
  bool get isVisible => !kReleaseMode;

  @override
  void update(double dt) => text = '${fpsComponent.fps.toStringAsFixed(0)} TPS';
}

class RenderFps<T extends TextRenderer> extends TextComponent with HasVisibility {
  RenderFps({
    super.position,
    super.size,
    super.scale,
    super.anchor,
    super.key,
  }) : super(priority: double.maxFinite.toInt());

  @override
  bool get isVisible => !kReleaseMode;

  @override
  void update(double dt) {}

  static const maxSnapshots = 100;
  final snapshots = <int>[];

  int previousFrame = 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (previousFrame > 0) {
      final delta = DateTime.timestamp().millisecondsSinceEpoch - previousFrame;
      if (snapshots.length == maxSnapshots) snapshots.removeAt(0);
      snapshots.add(delta);
      final average = snapshots.reduce((value, element) => value + element) / snapshots.length;
      text = '${(1000 / average).toStringAsFixed(0)} FPS';
    }
    previousFrame = DateTime.timestamp().millisecondsSinceEpoch;
  }
}
