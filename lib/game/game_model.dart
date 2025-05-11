import 'dart:async';

import 'package:commando24/game/decals.dart';
import 'package:commando24/game/entities/prisoners.dart';
import 'package:commando24/game/explosions.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/game_phase.dart';
import 'package:commando24/game/game_state.dart';
import 'package:commando24/game/hud.dart';
import 'package:commando24/game/level/level.dart';
import 'package:commando24/game/level/path_finder.dart';
import 'package:commando24/game/particles.dart';
import 'package:commando24/game/player/grenades.dart';
import 'package:commando24/game/player/player.dart';
import 'package:commando24/game/player/weapons.dart';
import 'package:commando24/game/weapons_hud.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/game_script_functions.dart';
import 'package:flame/components.dart';

extension GameContextExtensions on GameContext {
  GameModel get model => cache.putIfAbsent('model', () => GameModel());
}

class GameModel extends Component
    with AutoDispose, GameContext, GameScriptFunctions, HasAutoDisposeShortcuts, HasVisibility {
  //

  bool closed = false;

  @override
  FutureOr<void> add(Component component) {
    // TODO: Why did I do/need this?
    if (closed) throw 'no no: $component';
    return super.add(component);
  }

  @override
  onLoad() async {
    await add(game_state);
    await add(entities);
    await add(level);
    await add(prisoners);
    await add(weapons);
    await add(grenades);
    await add(particles);
    await add(explosions);
    await add(decals);
    await add(path_finder);

    await entities.add(player);

    final weapons_hud = WeaponsHud(stage);
    await hud.add(weapons_hud);
    removed.then((_) => weapons_hud.removeFromParent());

    closed = true;
  }

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    if (phase == GamePhase.game_paused) return;
    if (phase == GamePhase.game_over) return;
    if (phase == GamePhase.game_over_hiscore) return;
    super.updateTree(dt);
  }
}
