import 'package:commando24/core/common.dart';
import 'package:commando24/core/configuration.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/input/controls_ui.dart';
import 'package:commando24/input/game_pads_config.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

class Controls extends GameScriptComponent with ControlsUi, GamepadControls {
  @override
  void set_enabled(bool value) => ui_navigation_active = value;

  @override
  void onRemove() {
    super.onRemove();
    configuration.save();
    log_info('configuration saved');
  }

  @override
  onLoad() async {
    super.onLoad();

    textXY('Game Pad / Controller', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    textXY('Keyboard', _x_base, _y_base - 28, scale: 2, anchor: Anchor.topCenter);
    add_flow(_move, 16, _y_base, _col_width, _col_height, Anchor.topLeft);
    add_flow(_weapons, _x_base, _y_base, _col_width * 2 - 80, _col_height, Anchor.topCenter);
    add_flow(_soft_keys, game_width - 16, _y_base, _col_width, _col_height, Anchor.topRight);

    add_button('Back', 8, game_height - 8, anchor: Anchor.bottomLeft, onTap: pop_screen);

    highlight_down();
  }

  final _x_base = game_center.x;
  final _y_base = game_center.y + 80;
  final _col_width = game_width / 4;
  final _col_height = game_height / 2 - 96;

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.soft1)) _cancel_or_pop();
  }

  void _cancel_or_pop() {
    if (ui_navigation_active) {
      pop_screen();
    } else {
      cancel_configuration();
    }
  }
}

const _move = '''
MOVE / STRAFE
-------------------

WASD OR

HJKL OR

ARROW KEYS
''';

const _weapons = '''
WEAPONS
------------

V or M or Ctrl: Fire Primary

X or N or Space: Fire Secondary
''';

const _soft_keys = '''
SOFT KEYS
--------------

Escape: Left Soft Key

Enter: Right Soft Key
''';
