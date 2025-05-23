import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/hiscore.dart';
import 'package:commando24/input/game_keys.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/ui/soft_keys.dart';
import 'package:commando24/util/bitmap_font.dart';
import 'package:commando24/util/bitmap_text.dart';
import 'package:commando24/util/effects.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:flame/components.dart';

class HiscoreScreen extends GameScriptComponent with HasAutoDisposeShortcuts, KeyboardHandler, HasGameKeys {
  final _entry_size = Vector2(game_width, line_height);
  final _position = Vector2(0, line_height * 4);

  @override
  onLoad() async {
    add(sprite_comp('background.png'));

    font_select(tiny_font, scale: 1);
    textXY('Hiscore', center_x, 16, scale: 2);

    _add('Score', 'Round', 'Name');
    for (final entry in hiscore.entries) {
      final it = _add(entry.score.toString(), entry.level.toString(), entry.name);
      if (entry == hiscore.latestRank) {
        it.add(BlinkEffect(on: 0.75, off: 0.25));
      }
    }

    softkeys('Back', null, (_) => pop_screen());
  }

  _HiscoreEntry _add(String score, String level, String name) {
    final it = added(_HiscoreEntry(
      score,
      level,
      name,
      tiny_font,
      size: _entry_size,
      position: _position,
    ));
    _position.y += line_height;
    return it;
  }
}

class _HiscoreEntry extends PositionComponent with HasVisibility {
  final BitmapFont _font;

  _HiscoreEntry(
    String score,
    String level,
    String name,
    this._font, {
    required Vector2 size,
    super.position,
  }) : super(size: size) {
    add(BitmapText(
      text: score,
      position: Vector2(100, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));

    add(BitmapText(
      text: level,
      position: Vector2(160, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));

    add(BitmapText(
      text: name,
      position: Vector2(220, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));
  }
}
