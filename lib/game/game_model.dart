import 'package:commando24/game/game_context.dart';
import 'package:flame/components.dart';

import '../util/auto_dispose.dart';
import '../util/game_script_functions.dart';
import '../util/keys.dart';
import '../util/messaging.dart';
import '../util/on_message.dart';
import '../util/shortcuts.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'game_state.dart' as gs;
import 'level/level.dart';
import 'player.dart';

class GameModel extends Component with AutoDispose, GameScriptFunctions, HasAutoDisposeShortcuts, HasVisibility {
  GameModel({required this.keys}) {
    model = this;
  }

  final Keys keys;

  final state = gs.state;
  final level = Level();

  // final enemies = EnemySpawner();
  // final power_ups = PowerUps();
  // final laser = LaserWeapon();
  final player = Player();

  // final slow_down_area = SlowDownArea();
  // final plasma_blasts = PlasmaBlasts();

  GamePhase _phase = GamePhase.game_over;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    sendMessage(GamePhaseUpdate(_phase));
  }

  @override
  bool get is_active => phase == GamePhase.game_on;

  // Component

  @override
  onLoad() async {
    await add(state);
    // await add(visual);
    // await add(hiscore);
    await add(level);
    await add(player);

    // onMessage<PlayerReady>((it) => add(Ball()));
    onMessage<ExtraLife>((_) {
      state.lives++;
      // soundboard.play(Sound.extra_life_jingle);
    });

    // if (dev) {
    //   onKey('1', () => sendMessage(SpawnExtra(ExtraId.laser)));
    //   onKey('2', () => sendMessage(SpawnExtra(ExtraId.catcher)));
    //   onKey('3', () => sendMessage(SpawnExtra(ExtraId.expander)));
    //   onKey('4', () => sendMessage(SpawnExtra(ExtraId.disruptor)));
    //   onKey('5', () => sendMessage(SpawnExtra(ExtraId.slow_down)));
    //   onKey('6', () => sendMessage(SpawnExtra(ExtraId.multi_ball)));
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
    // }
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
