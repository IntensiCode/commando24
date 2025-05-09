import 'package:commando24/game/storage.dart';
import 'package:commando24/main_game.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_core/signals_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  log_level = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'commando24';
  runApp(GameWidget(game: MainGame()));
}
