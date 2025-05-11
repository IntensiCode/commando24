import 'dart:math';

import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/ui/soft_keys.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/bitmap_button.dart';
import 'package:commando24/util/bitmap_text.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/game_script_functions.dart';
import 'package:commando24/util/nine_patch_image.dart';
import 'package:flame/components.dart';

class SimpleGameDialog extends PositionComponent with AutoDispose, GameScriptFunctions, HasPaint {
  SimpleGameDialog(this._handlers, this._text, this._left, this._right, {this.shortcuts = false});

  final Map<GameKey, Function> _handlers;
  final String _text;
  final String? _left;
  final String? _right;
  final bool shortcuts;

  Keys? keys;

  @override
  onLoad() async {
    super.onLoad();

    final lw = tiny_font.lineWidth(_text);
    final w = max(lw + 16, 80.0) ~/ 8 * 8.0;
    final lh = tiny_font.lineHeight(1);
    final h = max(lh + 16, 24.0) ~/ 8 * 8.0;
    size.setValues(w, h);

    add(RectangleComponent(size: game_size, paint: pixel_paint()..color = shadow));

    final bg = atlas.sprite('button_plain.png');
    final dialog = PositionComponent(position: game_center, size: size, anchor: Anchor.center);
    dialog.position.y -= size.y;
    dialog.add(NinePatchComponent(image: bg, size: size));
    dialog.add(BitmapText(text: _text, position: size / 2, anchor: Anchor.center, font: tiny_font));

    if (_left != null) {
      await dialog.add(BitmapButton(
        bg_nine_patch: bg,
        text: _left,
        font: tiny_font,
        position: Vector2(0, size.y),
        anchor: Anchor.topLeft,
        onTap: () => _handle(SoftKey.left),
      ));
    }
    if (_right != null) {
      await dialog.add(BitmapButton(
        bg_nine_patch: bg,
        text: _right,
        font: tiny_font,
        position: Vector2(size.x, size.y),
        anchor: Anchor.topRight,
        onTap: () => _handle(SoftKey.right),
      ));
    }

    add(dialog);

    for (final it in children) {
      if (it is RectangleComponent) continue;
      it.fadeInDeep();
    }

    if (shortcuts) add(keys = Keys());
  }

  _handle(SoftKey it) {
    if (it == SoftKey.left) _handlers[GameKey.soft1]!();
    if (it == SoftKey.right) _handlers[GameKey.soft2]!();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys?.check_and_consume(GameKey.soft1) == true) _handlers[GameKey.soft1]!();
    if (keys?.check_and_consume(GameKey.soft2) == true) _handlers[GameKey.soft2]!();
    if (keys?.check_and_consume(GameKey.a_button) == true) _handlers[GameKey.soft2]!();
  }
}
