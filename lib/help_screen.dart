import 'package:commando24/components/flow_text.dart';
import 'package:commando24/components/soft_keys.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/keys.dart';
import 'package:flame/components.dart';

bool help_triggered_at_first_start = false;

class HelpScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('How To Play', center_x, 10, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/controls.txt'),
      font: tiny_font,
      position: Vector2(0, 25),
      size: Vector2(160, 160 - 16),
    ));

    add(FlowText(
      text: await game.assets.readFile('data/help.txt'),
      font: tiny_font,
      position: Vector2(center_x, 25),
      size: Vector2(160, 176),
    ));

    final label = help_triggered_at_first_start ? 'Start' : 'Back';
    softkeys(label, null, (_) => pop_screen());

    add(keys);
  }

  final keys = Keys();

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.fire1)) {
      pop_screen();
    }
  }
}
