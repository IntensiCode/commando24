import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_phase.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:flame_tiled/flame_tiled.dart';

class EnterRound with Message {}

class ExtraLife with Message {}

class GameComplete with Message {}

class GameOver with Message {}

class LevelComplete with Message {}

class LevelReady with Message {}

class LoadLevel with Message {}

class PlayerDied with Message {}

class PlayerDying with Message {}

class PlayerReady with Message {}

class Collected with Message {
  Collected(this.consumable);

  final LevelProp consumable;
}

class GamePhaseUpdate with Message {
  final GamePhase phase;

  GamePhaseUpdate(this.phase);
}

class LevelDataAvailable with Message {
  LevelDataAvailable(this.map);

  final TiledMap map;
}

class WeaponBonus with Message {
  WeaponBonus(this.type);

  WeaponType type;
}

class WeaponEmpty with Message {
  WeaponEmpty(this.type);

  WeaponType type;
}

class WeaponPickedUp with Message {
  WeaponPickedUp(this.type);

  WeaponType type;
}

class WeaponSwitched with Message {
  WeaponSwitched(this.type);

  WeaponType type;
}
