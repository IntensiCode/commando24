import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/ui/flow_text.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/ui/soft_keys.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:flame/components.dart';

class CreditsScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(sprite_comp('background.png'));

    font_select(tiny_font, scale: 1);
    textXY('Credits', center_x, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/credits.txt'),
      font: tiny_font,
      position: Vector2(0, 24),
      size: Vector2(320, 160 - 16),
    ));

    softkeys('Back', null, (_) => pop_screen());
  }
}
