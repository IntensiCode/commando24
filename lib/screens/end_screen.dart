import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/game_state.dart';
import 'package:commando24/game/hiscore.dart';
import 'package:commando24/ui/flow_text.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/ui/soft_keys.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:flame/components.dart';

class EndScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(sprite_comp('end.png'));

    font_select(tiny_font, scale: 1);
    textXY('The End', center_x, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/end.txt'),
      font: tiny_font,
      position: Vector2(0, 24),
      size: Vector2(256, 64 - 8),
    ));

    if (hiscore.isHiscoreRank(game_state.score)) {
      softkeys('Hiscore', null, (_) => show_screen(Screen.hiscore_enter));
    } else {
      clear_game_state();
      softkeys('Back', null, (_) => pop_screen());
    }

    soundboard.play_music('music/theme.mp3');
  }

  clear_game_state() async {
    await game_state.delete();
    game_state.reset();
  }
}
