import 'dart:async';

import 'package:commando24/core/common.dart';
import 'package:commando24/game/decals.dart';
import 'package:commando24/game/explosions.dart';
import 'package:commando24/game/hud.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/level/level_tiles.dart';
import 'package:commando24/game/particles.dart';
import 'package:commando24/game/player/weapons.dart';
import 'package:commando24/game/weapons_hud.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script_functions.dart';
import 'package:commando24/util/keys.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/shortcuts.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'level/level.dart';
import 'level/props/level_prop.dart';
import 'level/props/level_prop_extensions.dart';
import 'player/player.dart';

class GameModel extends Component with AutoDispose, GameScriptFunctions, HasAutoDisposeShortcuts, HasVisibility {
  GameModel({required this.keys}) {
    model = this;
  }

  final Keys keys;

  final state = GameState.instance;

  late final Level level;
  late final Player player;
  late final Weapons weapons;
  late final Particles particles;
  late final Explosions explosions;
  late final Decals decals;

  GamePhase _phase = GamePhase.game_over;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    sendMessage(GamePhaseUpdate(_phase));
  }

  @override
  bool get is_active => phase == GamePhase.game_on;

  final solids = <StackedTile>[];
  final consumables = <LevelProp>[];
  final destructibles = <LevelProp>[];
  final flammables = <LevelProp>[];

  Iterable<LevelObject> get obstacles sync* {
    yield* solids;
    yield* destructibles;
  }

  // Component

  @override
  FutureOr<void> add(Component component) {
    if (component is StackedTile) {
      _manage(component, solids);
    }
    if (component is LevelProp) {
      if (component.is_consumable) _manage(component, consumables);
      if (component.is_destructible) _manage(component, destructibles);
      if (component.is_flammable) _manage(component, flammables);
    }
    return super.add(component);
  }

  void _manage<T extends LevelObject>(T prop, List<T> list) {
    if (prop.isMounted) {
      list.add(prop);
    } else {
      prop.mounted.then((_) => list.add(prop));
    }
    prop.removed.then((_) => list.remove(prop));
  }

  @override
  onLoad() async {
    final atlas = await image('tileset.png');
    final sprites16 = sheetWH(atlas, 16, 16);
    final sprites32 = sheetWH(atlas, 32, 32);

    await add(state);
    await add(level = Level(atlas, sprites16));
    await add(player = Player(atlas));
    await add(weapons = Weapons(sprites16));
    await add(particles = Particles(sprites16));
    await add(explosions = Explosions(sprites32));
    await add(decals = Decals(sprites32));

    final weapons_hud = WeaponsHud(sprites32);
    await hud.add(weapons_hud);
    removed.then((_) => weapons_hud.removeFromParent());

    // onMessage<PlayerReady>((it) {});
    // onMessage<ExtraLife>((_) {
    //   state.lives++;
    //   // soundboard.play(Sound.extra_life_jingle);
    // });

    if (dev) _dev_keys();
  }

  void _dev_keys() {
    logInfo('DEV KEYS');
    // onKey('x', () => sendMessage(WeaponBonus(WeaponType.assault_rifle)));
    // onKey('<A-2>', () => sendMessage(WeaponBonus(WeaponType.bazooka)));
    // onKey('<A-3>', () => sendMessage(WeaponBonus(WeaponType.flame_thrower)));
    // onKey('<A-4>', () => sendMessage(WeaponBonus(WeaponType.machine_gun)));
    // onKey('<A-5>', () => sendMessage(WeaponBonus(WeaponType.smg)));
    // onKey('<A-6>', () => sendMessage(WeaponBonus(WeaponType.shotgun)));

    //   onKey('7', () => sendMessage(SpawnExtra(ExtraId.extra_life)));
    //   onKey('b', () => add(Ball()));
    //   onKey('d', () => state.lives = 1);
    //   onKey('g', () => sendMessage(GameComplete()));
    //   onKey('l', () => sendMessage(LevelComplete()));
    //   onKey('p', () => state.blasts++);
    //   onKey('s', () => state.hack_hiscore());
    //   onKey('x', () => phase = GamePhase.game_over);
    //
    //   onKey('e', () {
    //     state.level_number_starting_at_1 = 33;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('h', () {
    //     state.hack_hiscore();
    //     phase = GamePhase.game_over_hiscore;
    //   });
    //   onKey('j', () {
    //     state.level_number_starting_at_1++;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('k', () {
    //     state.level_number_starting_at_1--;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('r', () {
    //     removeAll(children.whereType<Ball>());
    //     add(Ball());
    //   });
    //
    //   onKey('J', () {
    //     state.level_number_starting_at_1 += 5;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('K', () {
    //     state.level_number_starting_at_1 -= 5;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //
    //   onKey('<A-j>', () {
    //     state.level_number_starting_at_1 += 10;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('<A-k>', () {
    //     state.level_number_starting_at_1 -= 10;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
  }

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    if (phase == GamePhase.confirm_exit) return;
    if (phase == GamePhase.game_paused) return;
    if (phase == GamePhase.game_over) return;
    if (phase == GamePhase.game_over_hiscore) return;
    super.updateTree(dt);
  }
}
