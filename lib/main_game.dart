import 'dart:async';

import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/aural/music_score.dart';
import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/debug_overlay.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/main_controller.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/performance.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'game/hud.dart';

class MainGame extends FlameGame<MainController>
    with HasKeyboardHandlerComponents, Messaging, Shortcuts, HasPerformanceTracker {
  //
  final _ticker = Ticker(ticks: tps);

  MainGame() : super(world: MainController()) {
    game = this;
    images = this.images;
    pauseWhenBackgrounded = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: game_width,
      height: game_height,
      hudComponents: [
        if (!kReleaseMode) _ticks(),
        if (!kReleaseMode) _frames(),
        if (!kReleaseMode) DebugOverlay(),
      ],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    // camera.viewfinder.position = Vector2(game_width / 2, game_height / 2);
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

    atlas = await game.loadTextureAtlas();

    await add(audio);
    await add(music_score);
    await load_fonts(assets);

    if (dev) {
      log_verbose('force preload audio');
      await audio.preload();
    }
  }

  @override
  void update(double dt) {
    _ticker.generateTicksFor(dt, (it) => super.update(it));
  }
}
