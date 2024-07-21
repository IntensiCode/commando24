import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_core/signals_core.dart';

import 'main_game.dart';
import 'game/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  logLevel = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'commando24';
  runApp(GameWidget(game: MainGame()));
}
