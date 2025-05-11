import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/game/military_text.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/util/auto_dispose.dart';

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
  void onMount() => on_key('<Space>', () => _leave());

  @override
  Future onLoad() async {
    if (dev) soundboard.fade_out_music();
    await add(MilitaryText(font: mini_font, font_scale: 2, text: _text, when_done: _leave));
  }

  void _leave() {
    show_screen(Screen.title);
    removeFromParent();
  }
}
