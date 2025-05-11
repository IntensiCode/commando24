import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/game_model.dart';
import 'package:commando24/game/game_phase.dart';
import 'package:commando24/game/game_state.dart';
import 'package:commando24/game/hiscore.dart';
import 'package:commando24/game/hud.dart';
import 'package:commando24/game/level/level.dart';
import 'package:commando24/game/level_bonus.dart';
import 'package:commando24/game/military_text.dart';
import 'package:commando24/game/player/player.dart';
import 'package:commando24/game/player/player_state.dart';
import 'package:commando24/game/simple_game_dialog.dart';
import 'package:commando24/game/stage_cache.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/util/bitmap_button.dart';
import 'package:commando24/util/bitmap_text.dart';
import 'package:commando24/util/delayed.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';

/// Reminder to self: Controls the top-level game logic (here called [GamePhase]s) in contrast to the [GameModel]
/// handling the game-play
///
/// While the [GameModel] represents/manages the actual game-play, the [GameScreen] handles the overlays ("Game
/// Paused", etc) and un-/pausing the game-play as necessary. The top-level game state/phase related events are
/// handled here. Other components like [Level] for [LevelComplete] emit events and react directly to many events.
/// But the [GameScreen] handles the top-level progression of the game.
///
class GameScreen extends GameScriptComponent with GameContext, HasAutoDisposeShortcuts {
  final stage_keys = Keys();
  final stage_cache = StageCache();

  Component? _overlay;

  GamePhase _phase = GamePhase.game_over;

  @override
  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    send_message(GamePhaseUpdate(_phase));
  }

  GameScreen() {
    add(stage_keys);
    add(stage_cache);
  }

  @override
  bool get is_active => phase == GamePhase.game_on;

  @override
  void onRemove() {
    super.onRemove();
    // TODO should we not switch to a new world+cam when in game?
    game.camera.moveTo(Vector2.zero());
  }

  @override
  onLoad() async {
    super.onLoad();

    await add(hiscore);
    await add(model);

    on_message<PlayerReady>((_) => phase = GamePhase.game_on);
    on_message<LevelComplete>((_) => phase = GamePhase.next_round);
    on_message<GameComplete>((_) => phase = GamePhase.game_complete);
    on_message<GameOver>((_) => _show_game_over());
    on_message<PlayerDied>((_) => _on_player_died());

    on_message<GamePhaseUpdate>((it) {
      log_info('game phase update: ${it.phase}');
      _phase_handler(it.phase).call();
    });

    phase = GamePhase.enter_round;
  }

  void _on_player_died() {
    game_state.lives--;
    game_state.save_checkpoint();

    if (game_state.lives <= 0) {
      _show_game_over();
      return;
    }

    // add(Delayed(0.5, () {
    //   _switch_overlay(BitmapText(
    //     text: 'ROUND ${game_state.level_number_starting_at_1}',
    //     position: (game_size / 2)..y += 48,
    //     anchor: Anchor.center,
    //     font: mini_font,
    //   ));
    //   add(Delayed(1.0, () => player.reset(PlayerState.entering)));
    // }));
    add(Delayed(2.0, () => player.reset(PlayerState.entering)));
  }

  void _show_game_over() {
    if (hiscore.isHiscoreRank(game_state.score)) {
      phase = GamePhase.game_over_hiscore;
    } else {
      phase = GamePhase.game_over;
    }
  }

  Function _phase_handler(GamePhase it) => switch (it) {
        GamePhase.enter_round => _on_enter_round,
        GamePhase.game_complete => _on_game_complete,
        GamePhase.game_on => _on_game_on,
        GamePhase.game_over => _on_game_over,
        GamePhase.game_over_hiscore => _on_game_over_hiscore,
        GamePhase.game_paused => _on_game_paused,
        GamePhase.next_round => _on_next_round,
      };

  void _on_enter_round() async {
    send_message(EnterRound());

    final ok = await level.preload_level();
    if (ok) {
      _switch_overlay(MilitaryText(
        text: 'STAGE ${game_state.level_number_starting_at_1}\n${model.level.name}\nPREPARE TO FIGHT',
        font: mini_font,
        font_scale: 1,
        stay_seconds: dev ? 0.1 : 1.0,
        time_per_char: dev ? 0.01 : 0.1,
        when_done: () => send_message(LoadLevel()),
      ));
    } else {
      // TODO game complete?
      _show_game_over();
    }
  }

  void _on_game_on() {
    _switch_overlay(_make_in_game_overlay());
  }

  void _on_game_over() async {
    _switch_overlay(SimpleGameDialog(_key_handlers(), 'GAME OVER', 'TRY AGAIN', 'EXIT'));
  }

  void _on_game_over_hiscore() async {
    _switch_overlay(SimpleGameDialog(_key_handlers(), 'GAME OVER', null, 'ENTER HISCORE'));
  }

  void _on_game_paused() {
    _switch_overlay(SimpleGameDialog(_key_handlers(), 'GAME PAUSED', 'RESUME', 'EXIT'));
  }

  void _on_next_round() {
    _switch_overlay(LevelBonus(() {
      add(Delayed(0.5, () async {
        game_state.level_number_starting_at_1++;
        log_info('next round: ${game_state.level_number_starting_at_1}');
        await game_state.save_checkpoint();
        if (game_state.level_number_starting_at_1 == 2) {
          await save_not_first_time();
        }

        // really only for dev
        final ok = await level.preload_level();
        if (ok) {
          phase = GamePhase.enter_round;
        } else {
          _show_game_over();
        }
      }));
    }));
  }

  void _on_game_complete() {
    _switch_overlay(LevelBonus(() {
      add(Delayed(0.5, () async => show_screen(Screen.end)));
    }, game_complete: true));
  }

  void _on_new_game() {
    _overlay?.fadeOutDeep();
    game_state.reset();
    phase = GamePhase.enter_round;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final mapping = _key_handlers();
    for (final key in mapping.keys) {
      if (stage_keys.check_and_consume(key)) {
        mapping[key]?.call();
      }
    }
  }

  Map<GameKey, Function> _key_handlers() => switch (phase) {
        GamePhase.enter_round => {},
        GamePhase.game_complete => {},
        GamePhase.game_on => {
            GameKey.soft1: () => phase = GamePhase.game_paused,
            GameKey.soft2: () => phase = GamePhase.game_paused,
          },
        GamePhase.game_over => {
            GameKey.soft1: () => _on_new_game(),
            GameKey.soft2: () => show_screen(Screen.title),
          },
        GamePhase.game_over_hiscore => {
            GameKey.soft2: () => show_screen(Screen.hiscore_enter),
          },
        GamePhase.game_paused => {
            GameKey.soft1: () => phase = GamePhase.game_on,
            GameKey.soft2: () => show_screen(Screen.title),
            GameKey.a_button: () => phase = GamePhase.game_on,
          },
        GamePhase.next_round => {},
      };

  // Implementation

  void _switch_overlay(Component it) async {
    // fix for dev mode jumping between levels/phases
    for (final it in hud.children.whereType<BitmapText>()) {
      if (it != _overlay) it.fadeOutDeep();
    }

    _overlay?.fadeOutDeep();
    _overlay = it;
    await hud.add(it);
    if (it is BitmapText) it.fadeInDeep();
  }

  Component _make_in_game_overlay() => BitmapButton(
        bg_nine_patch: atlas.sprite('button_plain.png'),
        text: 'Pause',
        position: Vector2(game_width, game_height),
        anchor: Anchor.bottomRight,
        font: tiny_font,
        onTap: () => phase = GamePhase.game_paused,
      )..fadeInDeep();
}
