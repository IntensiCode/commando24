import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commando24/audio_menu_screen.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/credits_screen.dart';
import 'package:commando24/enter_hiscore_screen.dart';
import 'package:commando24/game/game_screen.dart';
import 'package:commando24/game/visual_configuration.dart';
import 'package:commando24/help_screen.dart';
import 'package:commando24/hiscore_screen.dart';
import 'package:commando24/options_screen.dart';
import 'package:commando24/splash_screen.dart';
import 'package:commando24/the_end_screen.dart';
import 'package:commando24/title_screen.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/shortcuts.dart';
import 'package:commando24/web_play_screen.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class MainController extends World with AutoDispose, HasAutoDisposeShortcuts implements ScreenNavigation {
  final _stack = <Screen>[];

  @override
  onLoad() async => messaging.listen<ShowScreen>((it) => showScreen(it.screen));

  @override
  void onMount() {
    if (dev && !kIsWeb) {
      showScreen(Screen.game);
    } else if (kIsWeb) {
      add(WebPlayScreen());
    } else {
      add(SplashScreen());
    }
    onKey('<A-a>', () => showScreen(Screen.audio_menu));
    onKey('<A-c>', () => showScreen(Screen.credits));
    onKey('<A-d>', () => debug = !debug);
    onKey('<A-e>', () => showScreen(Screen.the_end));
    onKey('<A-h>', () => showScreen(Screen.hiscore));
    onKey('<A-s>', () => showScreen(Screen.splash, skip_fade_in: true));
    onKey('<A-l>', () => showScreen(Screen.splash, skip_fade_in: true));
    onKey('<A-t>', () => showScreen(Screen.title));
  }

  @override
  void popScreen() {
    log_verbose('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    _stack.removeLastOrNull();
    showScreen(_stack.lastOrNull ?? Screen.title);
  }

  @override
  void pushScreen(Screen it) {
    log_verbose('push screen $it with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    _stack.add(it);
    showScreen(it);
  }

  Screen? _triggered;
  StackTrace? _previous;

  @override
  void showScreen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false}) {
    if (_triggered == screen) {
      log_error('duplicate trigger ignored: $screen', StackTrace.current);
      log_error('previous trigger', _previous);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    if (skip_fade_out) log_info('show $screen');
    log_verbose('screen stack: $_stack');
    log_verbose('children: ${children.map((it) => it.runtimeType)}');

    if (!skip_fade_out && children.isNotEmpty) {
      children.last.fadeOutDeep(and_remove: true);
      children.last.removed.then((_) {
        if (_triggered == screen) {
          _triggered = null;
        } else if (_triggered != screen) {
          return;
        }
        log_info('show $screen');
        showScreen(screen, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
      });
    } else {
      final it = added(_makeScreen(screen));
      if (screen != Screen.game && !skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.audio_menu => AudioMenuScreen(),
        Screen.credits => CreditsScreen(),
        Screen.enter_hiscore => EnterHiscoreScreen(),
        Screen.game => GameScreen(),
        Screen.help => HelpScreen(),
        Screen.hiscore => HiscoreScreen(),
        Screen.options => OptionsScreen(),
        Screen.splash => SplashScreen(),
        Screen.the_end => TheEndScreen(),
        Screen.title => TitleScreen(),
      };

  @override
  void renderTree(Canvas canvas) {
    if (visual.pixelate_screen) {
      final recorder = PictureRecorder();
      super.renderTree(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(game_width ~/ 1, game_height ~/ 1);
      canvas.drawImage(image, Offset.zero, pixel_paint());
      image.dispose();
      picture.dispose();
    } else {
      super.renderTree(canvas);
    }
  }
}
