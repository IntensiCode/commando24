import 'dart:ui';

import 'package:commando24/core/common.dart';
import 'package:commando24/post/post_process.dart';
import 'package:commando24/util/pixelate.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

class FlashScreen extends Component with HasPaint, PostProcess {
  final Color start = transparent;
  final Color end = white;
  final double seconds;

  FlashScreen({required this.seconds});

  double t = 0.0;

  @override
  void update(double dt) {
    super.update(dt);

    if (!active) return;

    t = (t + dt / seconds).clamp(0, 1);
    if (t < 1.0) return;

    active = false;

    if (game_post_process == this) game_post_process = null;
  }

  @override
  void post_process(Canvas canvas, Function(Canvas) render) {
    if (active) {
      final img = pixelate(game_width.toInt(), game_height.toInt(), (canvas) {
        render(canvas);
        final tt = Curves.bounceInOut.transform(t);
        paint.color = Color.lerp(start, end, tt)!;
        paint.colorFilter = ColorFilter.mode(paint.color, BlendMode.srcATop);
        canvas.drawRect(Rect.fromLTWH(0, 0, game_width, game_height), paint);
      });
      paint.color = white;
      canvas.drawImage(img, Offset.zero, paint);
    } else {
      render(canvas);
    }
  }
}
