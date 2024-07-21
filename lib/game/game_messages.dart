import 'package:flame_tiled/flame_tiled.dart';

import '../core/common.dart';
import 'game_phase.dart';

class EnterRound with Message {}

class ExtraLife with Message {}

class GameComplete with Message {}

class GameOver with Message {}

class LevelComplete with Message {}

class LevelDataAvailable with Message {
  LevelDataAvailable(this.map);

  final TiledMap map;
}

class LevelReady with Message {}

class LoadLevel with Message {}

class PlayerDied with Message {}

class PlayerDying with Message {}

class PlayerReady with Message {}

class GamePhaseUpdate with Message {
  final GamePhase phase;

  GamePhaseUpdate(this.phase);
}
