import 'dart:math';
import 'dart:ui';

import 'package:commando24/components/military_text.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/player/player_state.dart';
import 'package:commando24/util/bitmap_button.dart';
import 'package:commando24/util/bitmap_text.dart';
import 'package:commando24/util/delayed.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/keys.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/on_message.dart';
import 'package:commando24/util/shortcuts.dart';
import 'package:flame/components.dart';

import 'game_messages.dart';
import 'game_model.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'hiscore.dart';
import 'level_bonus.dart';
import 'scoreboard.dart';
import 'simple_game_dialog.dart';
import 'soundboard.dart';
import 'visual_configuration.dart';

/// Reminder to self: Controls the top-level game logic (here called [GamePhase]s) in contrast to the [GameModel]
/// handling the game-play
///
/// While the [GameModel] represents/manages the actual game-play, the [GameScreen] handles the overlays ("Game
/// Paused", etc) and un-/pausing the game-play as necessary. The top-level game state/phase related events are
/// handled here. Other components like [Level] for [LevelComplete] emit events and react directly to many events.
/// But the [GameScreen] handles the top-level progression of the game.
///
class GameScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  final _keys = Keys();

  final _scoreboard = Scoreboard();

  late final Image _button;
  late final model = GameModel(keys: _keys);

  Component? _overlay;

  // hack fix for the pseudo 'reenter round' phase:
  bool _temp_block_keys = false;

  @override
  void onRemove() {
    super.onRemove();
    // TODO should we not switch to a new world+cam when in game?
    game.camera.moveTo(Vector2.zero());
  }

  @override
  onLoad() async {
    super.onLoad();

    _button = await image('button_plain.png');

    await add(visual);
    await add(hiscore);
    await add(_keys);
    await add(model);
    await add(_scoreboard);

    onMessage<LevelComplete>((_) => model.phase = GamePhase.next_round);
    onMessage<PlayerReady>((_) => _on_enter_round_get_ready());
    onMessage<GameComplete>((_) => model.phase = GamePhase.game_complete);
    // onMessage<GameOver>((_) => _show_game_over());
    onMessage<PlayerDied>((_) => _on_vaus_lost());

    onMessage<GamePhaseUpdate>((it) {
      log_info('game phase update: ${it.phase}');
      _temp_block_keys = false;
      _phase_handler(it.phase).call();
    });

    model.phase = GamePhase.enter_round;

    soundboard.play_music('music/ingame.ogg');
  }

  void _on_vaus_lost() {
    state.lives--;
    if (state.lives <= 0) {
      _show_game_over();
      return;
    }

    // state.save_checkpoint();

    // special state: we still want GamePhase.game_on for power ups to drop etc.
    // enemies are handled via teleport. player is PlayerState.gone.

    // here we play Sound.vaus_lost and show a special overlay.

    _temp_block_keys = true;

    add(Delayed(0.5, () {
      _switch_overlay(BitmapText(
        text: 'ROUND ${model.state.level_number_starting_at_1}',
        position: (game_size / 2)..y += 48,
        anchor: Anchor.center,
        font: mini_font,
      ));

      add(Delayed(1.0, () => model.player.reset(PlayerState.entering)));

      // soundboard.play(Sound.vaus_lost, volume_factor: 2);
    }));
  }

  void _show_game_over() {
    if (hiscore.isHiscoreRank(state.score)) {
      model.phase = GamePhase.game_over_hiscore;
    } else {
      model.phase = GamePhase.game_over;
    }
  }

  Function _phase_handler(GamePhase it) => switch (it) {
        GamePhase.confirm_exit => _on_confirm_exit,
        GamePhase.enter_round => _on_enter_round,
        GamePhase.game_complete => _on_game_complete,
        GamePhase.game_on => _on_game_on,
        GamePhase.game_over => _on_game_over,
        GamePhase.game_over_hiscore => _on_game_over_hiscore,
        GamePhase.game_paused => _on_game_paused,
        GamePhase.next_round => _on_next_round,
      };

  void _on_confirm_exit() => _switch_overlay(SimpleGameDialog(
        _key_handlers(),
        'END GAME?',
        'NO',
        'YES',
      ));

  void _on_enter_round() async {
    sendMessage(EnterRound());

    final ok = await model.level.preload_level();
    if (ok) {
      _switch_overlay(MilitaryText(
        text: 'STAGE ${model.state.level_number_starting_at_1}\n${model.level.name}\nPREPARE TO FIGHT',
        font: mini_font,
        font_scale: 1,
        stay_seconds: dev ? 0.1 : 1.0,
        time_per_char: dev ? 0.01 : 0.1,
        when_done: () => sendMessage(LoadLevel()),
      ));
    } else {
      // TODO game complete?
      _show_game_over();
    }
  }

  void _on_enter_round_get_ready() {
    // if the player paused during pseudo "reenter_round" phase, the _overlay won't be the right one!

    // if (_overlay == null || _overlay is! BitmapText) {
    //   _switch_overlay(BitmapText(
    //     text: 'ROUND ${model.state.level_number_starting_at_1}',
    //     position: (game_size / 2)..y += 48,
    //     anchor: Anchor.center,
    //     font: mini_font,
    //   ));
    //   _overlay?.add(Delayed(0.5, () => _on_enter_round_get_ready()));
    //   return;
    // }
    //
    // final bt = _overlay as BitmapText;
    // bt.add(BitmapText(
    //   text: 'GET READY',
    //   position: Vector2(bt.width / 2, 12),
    //   anchor: Anchor.center,
    //   font: mini_font,
    // ));
    //
    // add(Delayed(2.0, () {
    //   bt.fadeOutDeep();
    //   _temp_block_keys = false;
    //   model.phase = GamePhase.game_on;
    // }));

    // soundboard.play_one_shot_sample('sound/get_ready.ogg');
  }

  void _on_game_on() => _switch_overlay(_make_in_game_overlay());

  void _on_game_over() async {
    _switch_overlay(SimpleGameDialog(
      _key_handlers(),
      'GAME OVER',
      'EXIT',
      'TRY AGAIN',
    ));

    soundboard.play_one_shot_sample('doh_laugh.ogg');
  }

  void _on_game_over_hiscore() async {
    _switch_overlay(SimpleGameDialog(
      _key_handlers(),
      'GAME OVER',
      null,
      'ENTER HISCORE',
    ));

    soundboard.play_one_shot_sample('doh_laugh.ogg');
  }

  void _on_game_paused() => _switch_overlay(SimpleGameDialog(
        _key_handlers(),
        'GAME PAUSED',
        'EXIT',
        'RESUME',
      ));

  void _on_next_round() {
    _switch_overlay(LevelBonus(() {
      add(Delayed(0.5, () async {
        model.state.level_number_starting_at_1++;
        log_info('next round: ${model.state.level_number_starting_at_1}');
        await model.state.save_checkpoint();
        if (model.state.level_number_starting_at_1 == 2) {
          await save_not_first_time();
        }

        // really only for dev
        final ok = await model.level.preload_level();
        if (ok) {
          model.phase = GamePhase.enter_round;
        } else {
          _show_game_over();
        }
      }));
    }));
  }

  void _on_game_complete() {
    _switch_overlay(LevelBonus(() {
      add(Delayed(0.5, () async {
        showScreen(Screen.the_end);
      }));
    }, game_complete: true));
  }

  void _on_new_game() {
    _overlay?.fadeOutDeep();
    state.reset();
    model.phase = GamePhase.enter_round;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final mapping = _key_handlers();
    for (final key in mapping.keys) {
      if (_keys.check_and_consume(key)) {
        mapping[key]?.call();
      }
    }
  }

  Map<GameKey, Function> _key_handlers() => switch (model.phase) {
        GamePhase.confirm_exit => {
            GameKey.soft1: () => model.phase = GamePhase.game_on,
            GameKey.soft2: () => showScreen(Screen.title),
          },
        GamePhase.enter_round => {},
        GamePhase.game_complete => {},
        GamePhase.game_on => {
            GameKey.soft1: () {
              if (!_temp_block_keys) model.phase = GamePhase.confirm_exit;
            },
            GameKey.soft2: () {
              if (!_temp_block_keys) model.phase = GamePhase.game_paused;
            },
          },
        GamePhase.game_over => {
            GameKey.soft1: () {
              _clear_game_state();
              showScreen(Screen.title);
            },
            GameKey.soft2: () {
              _clear_game_state();
              _on_new_game();
            },
          },
        GamePhase.game_over_hiscore => {
            GameKey.soft2: () => showScreen(Screen.enter_hiscore),
          },
        GamePhase.game_paused => {
            GameKey.soft1: () => showScreen(Screen.title),
            GameKey.soft2: () => model.phase = GamePhase.game_on,
            GameKey.fire1: () => model.phase = GamePhase.game_on,
          },
        GamePhase.next_round => {},
      };

  _clear_game_state() async {
    model.state.reset();
    await model.state.delete();
  }

  // Implementation

  void _switch_overlay(Component it) async {
    // fix for dev mode jumping between levels/phases
    for (final it in children.whereType<BitmapText>()) {
      if (it != _overlay) it.fadeOutDeep();
    }

    _overlay?.fadeOutDeep();
    _overlay = it;
    await add(it);
    if (it is BitmapText) it.fadeInDeep();
  }

  Component _make_in_game_overlay() => Component(children: [
        BitmapButton(
          bg_nine_patch: _button,
          text: 'Exit',
          position: Vector2(0, 32),
          anchor: Anchor.topLeft,
          font: tiny_font,
          onTap: (_) => model.phase = GamePhase.confirm_exit,
        )..angle = -pi / 2,
        BitmapButton(
          bg_nine_patch: _button,
          text: 'Pause',
          position: Vector2(0, game_height + 16),
          anchor: Anchor.bottomLeft,
          font: tiny_font,
          onTap: (_) => model.phase = GamePhase.game_paused,
        )..angle = -pi / 2,
      ])
        ..fadeInDeep();
}
