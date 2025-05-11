import 'package:commando24/core/storage.dart';
import 'package:commando24/main_game.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  log_level = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'commando24';
  final game = MainGame();
  final widget = GameWidget(game: game);
  if (kDebugMode) {
    log_verbose('Adding debug listener for right-click panning and zooming');
    runApp(_with_mouse_controls(widget, game, widget));
  } else {
    runApp(widget);
  }
}

Widget _with_mouse_controls(Widget rootWidget, MainGame game, GameWidget<MainGame> gameWidget) {
  rootWidget = Listener(
    onPointerMove: (event) {
      if (event.buttons == kMiddleMouseButton) {
        _update_pan(event, game);
      }
    },
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        _update_zoom(event, game);
      }
    },
    child: gameWidget,
  );
  return rootWidget;
}

void _update_pan(PointerMoveEvent event, MainGame game) {
  final camera = game.camera;
  if (!camera.isMounted) return;

  final screenDelta = Vector2(event.delta.dx, event.delta.dy);
  final adjustment = screenDelta / camera.viewfinder.zoom;
  camera.viewfinder.position -= adjustment;
}

void _update_zoom(PointerScrollEvent event, MainGame game) {
  final camera = game.camera;
  if (!camera.isMounted) return;

  final direction = event.scrollDelta.dy.sign;
  if (direction == 0) return;

  const baseZoomFactor = 0.1; // Adjust sensitivity as needed
  final currentZoom = camera.viewfinder.zoom;
  // Make the zoom step proportional to the current zoom level
  final zoomStep = currentZoom * baseZoomFactor;
  final newZoom = (currentZoom - direction * zoomStep).clamp(0.1, 5.0);

  if (newZoom == currentZoom) return;

  // Zoom towards cursor position
  // final pos = event.position.toVector2();
  // final worldPos = camera.globalToLocal(pos);
  final cameraPos = camera.viewfinder.position;
  // final zoomRatio = currentZoom / newZoom;
  // final adjustment = (worldPos - cameraPos) * (1 - zoomRatio);

  camera.viewfinder.zoom = newZoom;
  camera.viewfinder.position = cameraPos;
}
