import 'package:commando24/components/military_text.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/shortcuts.dart';

class SplashScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  final _text = '''
  An
  IntensiCode
  Presentation
  ~
  A
  PsychoCell
  Game
  ~
  Approved By
  The Military
  ''';

  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  Future onLoad() async {
    if (dev) soundboard.fade_out_music();
    await add(MilitaryText(font: mini_font, font_scale: 2, text: _text, when_done: _leave));
  }

  void _leave() {
    show_screen(Screen.title, skip_fade_out: true, skip_fade_in: true);
    removeFromParent();
  }
}
