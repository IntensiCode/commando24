import 'dart:async';

import 'package:commando24/core/common.dart';
import 'package:commando24/game/hud.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/main_controller.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/performance.dart';
import 'package:commando24/util/shortcuts.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

class MainGame extends FlameGame<MainController>
    with HasKeyboardHandlerComponents, Messaging, Shortcuts, HasPerformanceTracker, ScrollDetector {
  //
  final _ticker = Ticker(ticks: tps);

  MainGame() : super(world: MainController()) {
    game = this;
    images = this.images;
  }

  @override
  onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: game_width,
      height: game_height,
      hudComponents: [_ticks(), _frames()],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport.add(hud);
  }

  _ticks() => RenderTps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );

  _frames() => RenderFps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 8),
        anchor: Anchor.topLeft,
      );

  @override
  Future onLoad() async {
    super.onLoad();
    await add(soundboard);
    await loadFonts(assets);
  }

  @override
  update(double dt) => _ticker.generateTicksFor(dt, (it) => super.update(it));

  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);
    if (info.scrollDelta.global.y == 0) return;
    send(MouseWheel(info.scrollDelta.global.y.sign));
  }
}
