import 'package:collection/collection.dart';
import 'package:commando24/aural/audio_menu.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/configuration.dart';
import 'package:commando24/core/debug_overlay.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/game/game_screen.dart';
import 'package:commando24/game/level/path_finder.dart';
import 'package:commando24/input/controls.dart';
import 'package:commando24/input/controls_gamepad.dart';
import 'package:commando24/input/shortcuts.dart';
import 'package:commando24/post/fade_screen.dart';
import 'package:commando24/post/post_process.dart';
import 'package:commando24/screens/credits_screen.dart';
import 'package:commando24/screens/end_screen.dart';
import 'package:commando24/screens/enter_hiscore_screen.dart';
import 'package:commando24/screens/hiscore_screen.dart';
import 'package:commando24/screens/options_screen.dart';
import 'package:commando24/screens/title_screen.dart';
import 'package:commando24/screens/web_play_screen.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/grab_input.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class MainController extends World
    with AutoDispose, HasAutoDisposeShortcuts, HasCollisionDetection<Sweep<ShapeHitbox>>
    implements ScreenNavigation {
  //
  final _screen_holder = PostFxScreenHolder();

  Iterable<Component> get _screens => _screen_holder.children;

  @override // IIRC this is to have the SelectGamePad screen capture all input!?
  bool get is_active => !_screens.any((it) => it is GrabInput);

  final _stack = <Screen>[];

  @override
  onLoad() async {
    super.onLoad();
    add(_screen_holder);
    await configuration.load();
    on_message<ShowScreen>((it) => show_screen(it.screen));
  }

  @override
  void onMount() {
    super.onMount();

    if (dev) {
      show_screen(Screen.game);
    } else {
      _screen_holder.add(WebPlayScreen());
    }

    if (dev) {
      on_keys(['<A-d>', '='], (_) {
        debug = !debug;
        log_level = debug ? LogLevel.debug : LogLevel.info;
        show_debug("Debug Mode: $debug");
      });
      on_keys(['<A-p>', '='], (_) {
        debug_path_finder = !debug_path_finder;
        show_debug("Debug Path Finder: $debug_path_finder");
      });
      on_keys(['<A-v>'], (_) {
        if (log_level == LogLevel.verbose) {
          log_level = debug ? LogLevel.debug : LogLevel.info;
        } else {
          log_level = LogLevel.verbose;
        }
      });

      on_keys(['1'], (_) => push_screen(Screen.game));
      on_keys(['7'], (_) => push_screen(Screen.credits));
      on_keys(['8'], (_) => push_screen(Screen.audio));
      on_keys(['9'], (_) => push_screen(Screen.controls));
      on_keys(['0'], (_) => show_screen(Screen.title));
    }
  }

  void _log(String hint) {
    log_info('$hint (stack=$_stack children=${_screens.map((it) => it.runtimeType)})');
  }

  @override
  void pop_screen() {
    _log('pop screen');
    show_screen(_stack.removeLastOrNull() ?? Screen.title);
  }

  @override
  void push_screen(Screen it) {
    _log('push screen: $it triggered: $_triggered');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    if (_triggered != null) _stack.add(_triggered!);
    show_screen(it);
  }

  Screen? _triggered;
  StackTrace? _previous;

  @override
  void show_screen(Screen screen, {ScreenTransition transition = ScreenTransition.fade_out_then_in}) {
    if (_triggered == screen) {
      _log('show $screen');
      log_error('duplicate trigger ignored: $screen previous: $_previous', StackTrace.current);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    if (_screens.length > 1) _log('show $screen');

    void call_again() {
      // still the same? you never know.. :]
      if (_triggered == screen) {
        _triggered = null;
        show_screen(screen, transition: transition);
      } else {
        log_warn('triggered screen changed: $screen != $_triggered');
        log_warn('show $screen with stack=$_stack and children=${_screens.map((it) => it.runtimeType)}');
      }
    }

    const fade_duration = 0.2;

    final out = _screens.lastOrNull;
    if (out != null) {
      switch (transition) {
        case ScreenTransition.cross_fade:
          game_post_process = FadeScreen.fade_out(seconds: fade_duration, and_remove: out);
          break;
        case ScreenTransition.fade_out_then_in:
          game_post_process = FadeScreen.fade_out(seconds: fade_duration, and_remove: out);
          out.removed.then((_) => call_again());
          return;
        case ScreenTransition.switch_in_place:
          out.removeFromParent();
          break;
        case ScreenTransition.remove_then_add:
          out.removeFromParent();
          out.removed.then((_) => call_again());
          return;
      }
    }

    final it = _screen_holder.added(_makeScreen(screen));
    switch (transition) {
      case ScreenTransition.cross_fade:
        it.mounted.then((_) {
          game_post_process = FadeScreen.fade_in(seconds: fade_duration);
        });
        break;
      case ScreenTransition.fade_out_then_in:
        it.mounted.then((_) {
          game_post_process = FadeScreen.fade_in(seconds: fade_duration);
        });
        break;
      case ScreenTransition.switch_in_place:
        break;
      case ScreenTransition.remove_then_add:
        break;
    }

    messaging.send(ScreenShowing(screen));
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.audio => AudioMenu(),
        Screen.controls => Controls(),
        Screen.controls_gamepad => ControlsGamepad(),
        Screen.credits => CreditsScreen(),
        Screen.end => EndScreen(),
        Screen.game => GameScreen(),
        Screen.hiscore => HiscoreScreen(),
        Screen.hiscore_enter => EnterHiscoreScreen(),
        Screen.options => OptionsScreen(),
        Screen.title => TitleScreen(),
      };
}
