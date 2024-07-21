import 'package:flame/components.dart';
import 'package:signals_core/signals_core.dart';

import '../util/auto_dispose.dart';
import '../util/game_script_functions.dart';
import 'game_context.dart';

class Scoreboard extends PositionComponent with AutoDispose, GameContext, HasPaint, HasVisibility, GameScriptFunctions {
  @override
  onLoad() async {
    super.onLoad();
    //
    // size.setValues(320 - 216, game_height);
    // position.setValues(216, 0);
    //
    // // await add(await sprite_comp(
    // //   'scoreboard_title.png',
    // //   position: Vector2(size.x / 2, 0),
    // //   anchor: Anchor.topCenter,
    // // ));
    //
    // // too much 64 :-D
    // // fontSelect(fancy_font, scale: 1);
    // // await add(textXY('PLAYER 1', size.x / 2, 41, anchor: Anchor.topCenter));
    // // await add(textXY('########', size.x / 2, 51, anchor: Anchor.topCenter));
    // // await add(textXY('#      #', size.x / 2, 62, anchor: Anchor.topCenter));
    // // await add(textXY('#      #', size.x / 2, 73, anchor: Anchor.topCenter));
    // // await add(textXY('#      #', size.x / 2, 84, anchor: Anchor.topCenter));
    // // await add(textXY('#      #', size.x / 2, 95, anchor: Anchor.topCenter));
    // // await add(textXY('########', size.x / 2, 106, anchor: Anchor.topCenter));
    //
    // fontSelect(fancy_font, scale: 1);
    // await add(textXY('PLAYER 1', size.x / 2, 45, anchor: Anchor.topCenter));
    //
    // final changes = [
    //   level_time,
    //   show_new_hiscore,
    //   blink_high_score,
    //   toggle_high_score,
    //   blink_ranked_score,
    //   toggle_ranked_score,
    //   ...stats.values,
    // ];
    //
    // final combined = computed(() => changes.map((it) => it.value).join(','));
    // effect(() => dirty = combined.value.isNotEmpty);
  }

  late final level_time = autoDispose('level_time', signal(-1, debugLabel: 'level_time'));

  int? display_score;
  int? display_round;
  int? display_lives;
  int? display_blasts;

  double highlight_high_score = 0;
  double highlight_good_score = 0;
  double highlight_round = 0;
  double highlight_lives = 0;
  double highlight_blasts = 0;

  late final show_new_hiscore = autoDispose('show_new_hiscore', signal(false));
  late final blink_high_score = autoDispose('blink_high_score', signal(false));
  late final toggle_high_score = autoDispose('toggle_high_score', signal(false));
  late final blink_ranked_score = autoDispose('blink_ranked_score', signal(false));
  late final toggle_ranked_score = autoDispose('toggle_ranked_score', signal(false));

  late final stats = <String, Signal<int?>>{
    'EXPAND ': autoDispose('expand', signal(null)),
    'DISRUPT': autoDispose('disrupt', signal(null)),
    'LASER  ': autoDispose('laser', signal(null)),
    'CATCH  ': autoDispose('catch', signal(null)),
    'SLOW   ': autoDispose('slow', signal(null)),
  };

  bool dirty = true;

//   @override
//   void update(double dt) {
//     super.update(dt);
//
//     level_time.value = level.level_time.round();
//
//     // stats['EXPAND ']?.value = player.expanded_seconds;
//     // stats['LASER  ']?.value = player.laser_seconds;
//     // stats['CATCH  ']?.value = player.catcher_seconds;
//     // stats['SLOW   ']?.value = model.slow_down_area.slow_down_seconds;
//     //
//     // final balls = top_level_children<Ball>();
//     // final max_disrupt = balls.map((it) => it.disruptor.round()).maxOrNull;
//     // stats['DISRUPT']?.value = ((max_disrupt ?? 0) > 0) ? max_disrupt : null;
//
//     if (display_score != game_state.score) {
//       dirty = true;
//
//       if (display_score != null) {
//         final was = display_score;
//         display_score = lerpDouble(display_score!, game_state.score, 0.1)!.toInt();
//         if (display_score == was && display_score! < game_state.score) {
//           display_score = display_score! + 1;
//         }
//       } else {
//         display_score = game_state.score;
//       }
//
//       if (hiscore.isNewHiscore(display_score!)) {
//         highlight_high_score = 1;
//         highlight_good_score = 0;
//         toggle_ranked_score.value = false;
//         if (!show_new_hiscore.value) {
//           soundboard.play_one_shot_sample('sound/hiscore.ogg');
//         }
//         show_new_hiscore.value = true;
//       } else if (hiscore.isHiscoreRank(display_score!) && highlight_good_score == 0) {
//         highlight_good_score = 1;
//       }
//     }
//
//     if (highlight_high_score > 0) {
//       highlight_high_score -= min(highlight_high_score, dt / 3);
//       if (highlight_high_score <= 0) {
//         highlight_high_score = 1;
//       }
//       toggle_high_score.value = highlight_high_score < 0.5;
//       blink_high_score.value = (highlight_high_score % 0.5) < 0.2;
//       blink_ranked_score.value = false;
//     }
//     if (highlight_good_score > 0) {
//       highlight_good_score -= min(highlight_good_score, dt / 3);
//       if (highlight_good_score <= 0) {
//         highlight_good_score = 1;
//       }
//       toggle_ranked_score.value = highlight_good_score < 0.5;
//       blink_ranked_score.value = (highlight_good_score % 0.5) < 0.2;
//     }
//
//     if (display_round != game_state.level_number_starting_at_1) {
//       dirty = true;
//       if (display_round != null) highlight_round += 1;
//       display_round = game_state.level_number_starting_at_1;
//     }
//
//     if (display_lives != game_state.lives) {
//       dirty = true;
//       if (display_lives != null) highlight_lives += 1;
//       display_lives = game_state.lives;
//     }
//
//     if (display_blasts != game_state.blasts) {
//       dirty = true;
//       if (display_blasts != null) highlight_blasts += 1;
//       display_blasts = game_state.blasts;
//     }
//
//     if (highlight_round > 0) {
//       dirty = true;
//       highlight_round -= min(highlight_round, dt);
//     }
//     if (highlight_lives > 0) {
//       dirty = true;
//       highlight_lives -= min(highlight_lives, dt);
//     }
//     if (highlight_blasts > 0) {
//       dirty = true;
//       highlight_blasts -= min(highlight_blasts, dt);
//     }
//   }
//
//   Image? _snapshot;
//
//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);
//
//     if (dirty || _snapshot == null) {
//       dirty = false;
//       final recorder = PictureRecorder();
//       _render_into(Canvas(recorder));
//       final picture = recorder.endRecording();
//       _snapshot?.dispose();
//       _snapshot = picture.toImageSync(size.x.toInt(), size.y.toInt());
//       picture.dispose();
//     }
//     canvas.drawImage(_snapshot!, Offset.zero, paint);
//   }
//
//   void _render_into(Canvas canvas) {
//     mini_font.paint.opacity = 1;
//
//     fontSelect(mini_font, scale: 1);
//     var label = toggle_high_score.value ? '*** NEW ***' : 'HIGH SCORE';
//     mini_font.drawStringAligned(canvas, size.x / 2, 24, label, Anchor.topCenter);
//
//     if (!blink_high_score.value) {
//       final hiscore_ = show_new_hiscore.value
//           ? display_score!.toString().padLeft(7, '0')
//           : hiscore.entries.first.score.toString().padLeft(7, '0');
//       mini_font.drawStringAligned(canvas, size.x / 2, 32, hiscore_, Anchor.topCenter);
//     }
//
//     label = toggle_ranked_score.value ? 'RANKED #${hiscore.rank(display_score!)}' : 'SCORE';
//     mini_font.drawStringAligned(canvas, size.x / 2, 58, label, Anchor.topCenter);
//
//     if (!blink_ranked_score.value) {
//       final score = (display_score ?? game_state.score).toString().padLeft(7, '0');
//       mini_font.drawStringAligned(canvas, size.x / 2, 66, score, Anchor.topCenter);
//     }
//
//     final round = game_state.level_number_starting_at_1.toString().padLeft(2, ' ');
//     if (highlight_round > 0) mini_font.paint.opacity = (highlight_round * 4) % 1;
//     mini_font.drawStringAligned(canvas, size.x / 2, 76, 'ROUND $round', Anchor.topCenter);
//     mini_font.paint.opacity = 1;
//
//     final lives = game_state.lives.toString().padLeft(2, ' ');
//     if (highlight_lives > 0) mini_font.paint.opacity = (highlight_lives * 4) % 1;
//     mini_font.drawStringAligned(canvas, size.x / 2, 84, 'LIVES $lives', Anchor.topCenter);
//     mini_font.paint.opacity = 1;
//
//     final blasts = game_state.blasts.toString().padLeft(2, ' ');
//     if (highlight_blasts > 0) mini_font.paint.opacity = (highlight_blasts * 4) % 1;
//     mini_font.drawStringAligned(canvas, size.x / 2, 92, 'BLAST $blasts', Anchor.topCenter);
//     mini_font.paint.opacity = 1;
//
//     if (level.level_time > 0) {
//       final bonus = level.level_time.round().toString().padLeft(2, ' ');
//       mini_font.drawStringAligned(canvas, size.x / 2, 104, 'BONUS $bonus', Anchor.topCenter);
//     }
//
//     var stats_y = 116.0;
//     for (final it in stats.entries) {
//       if (it.value.value == null) continue;
//       final line = '${it.key} ${it.value}';
//       mini_font.drawStringAligned(canvas, size.x / 2, stats_y, line, Anchor.topCenter);
//       stats_y += 12;
//     }
//   }
// }
//
// extension on Player {
//   int? get expanded_seconds {
//     if (expanded == 0) return null;
//     return expanded.round();
//   }
//
//   int? get catcher_seconds {
//     if (!is_actual_catcher) return null;
//     if (mode_time == 0) return null;
//     return mode_time.round();
//   }
//
//   int? get laser_seconds {
//     if (!in_laser_mode) return null;
//     if (mode_time == 0) return null;
//     return mode_time.round();
//   }
}

// extension on SlowDownArea {
//   int? get slow_down_seconds {
//     if (slow_down_time == 0) return null;
//     return slow_down_time.round();
//   }
// }
