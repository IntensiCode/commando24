import 'package:commando24/components/flow_text.dart';
import 'package:commando24/components/soft_keys.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/game_state.dart';
import 'package:commando24/game/hiscore.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:flame/components.dart';

class TheEndScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('end.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('The End', center_x, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/end.txt'),
      font: tiny_font,
      position: Vector2(0, 24),
      size: Vector2(256, 64 - 8),
    ));

    if (hiscore.isHiscoreRank(state.score)) {
      softkeys('Hiscore', null, (_) => show_screen(Screen.enter_hiscore));
    } else {
      clear_game_state();
      softkeys('Back', null, (_) => pop_screen());
    }

    soundboard.play_music('music/theme.mp3');
  }

  clear_game_state() async {
    await state.delete();
    state.reset();
  }
}
