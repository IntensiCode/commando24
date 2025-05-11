import 'package:commando24/components/basic_menu.dart';
import 'package:commando24/components/basic_menu_button.dart';
import 'package:commando24/components/flow_text.dart';
import 'package:commando24/components/soft_keys.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_keys.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/shortcuts.dart';
import 'package:flame/components.dart';

enum OptionsMenuEntry {
  pixelate,
  pixelate_screen,
  animate_stars,
}

class OptionsScreen extends GameScriptComponent with HasAutoDisposeShortcuts, KeyboardHandler, HasGameKeys {
  static OptionsMenuEntry? rememberSelection;

  late final BasicMenuButton pixelate;
  late final BasicMenuButton pixelate_screen;
  late final BasicMenuButton animate_stars;

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('Video Mode', center_x, 16, scale: 2);

    final buttonSheet = await sheetI('button_option.png', 1, 2);
    final menu = added(BasicMenu<OptionsMenuEntry>(
      button: buttonSheet,
      font: tiny_font,
      onSelected: _selected,
    ));
    pixelate = menu.addEntry(OptionsMenuEntry.pixelate, 'Pixelate FX', anchor: Anchor.centerLeft);
    pixelate_screen = menu.addEntry(OptionsMenuEntry.pixelate_screen, 'Pixelate Screen', anchor: Anchor.centerLeft);
    animate_stars = menu.addEntry(OptionsMenuEntry.animate_stars, 'Animate Stars', anchor: Anchor.centerLeft);

    // pixelate.checked = visual.pixelate;
    // pixelate_screen.checked = visual.pixelate_screen;
    // animate_stars.checked = visual.animate_stars;

    menu.position.setFrom(game_center);
    menu.anchor = Anchor.center;

    rememberSelection ??= menu.entries.first;

    menu.preselectEntry(rememberSelection);
    menu.onPreselected = (it) => rememberSelection = it;

    softkeys('Back', null, (_) => pop_screen());

    add(FlowText(
      text: '"Pixelate Screen" is a bit '
          'more retro, but does not play '
          'well with the "hi-res physics". '
          'Give it a try anyway!\n\n'
          '"Animate Stars" may break rendering on some devices.',
      font: tiny_font,
      insets: Vector2(4, 4),
      position: Vector2(103, 151),
      size: Vector2(216, 48),
      anchor: Anchor.topLeft,
    ));
  }

  void _selected(OptionsMenuEntry it) {
    log_info('Selected: $it');
    switch (it) {
      case OptionsMenuEntry.pixelate:
      // visual.pixelate = !visual.pixelate;
      case OptionsMenuEntry.pixelate_screen:
      // visual.pixelate_screen = !visual.pixelate_screen;
      case OptionsMenuEntry.animate_stars:
      // visual.animate_stars = !visual.animate_stars;
    }
    // pixelate.checked = visual.pixelate;
    // pixelate_screen.checked = visual.pixelate_screen;
    // animate_stars.checked = visual.animate_stars;
  }
}
