import 'package:commando24/core/common.dart';

enum Screen {
  audio,
  controls,
  controls_gamepad,
  credits,
  end,
  game,
  hiscore,
  hiscore_enter,
  options,
  title,
}

class ShowScreen with Message {
  ShowScreen(this.screen);

  final Screen screen;
}

class ScreenShowing with Message {
  ScreenShowing(this.screen);

  final Screen screen;
}

enum ScreenTransition {
  cross_fade,
  fade_out_then_in,
  switch_in_place,
  remove_then_add,
}

abstract interface class ScreenNavigation {
  void pop_screen();

  void push_screen(Screen screen);

  void show_screen(
    Screen screen, {
    ScreenTransition transition = ScreenTransition.fade_out_then_in,
  });
}

void pop_screen() {
  final world = game.world;
  (world as ScreenNavigation).pop_screen();
}

void push_screen(Screen it) {
  final world = game.world;
  (world as ScreenNavigation).push_screen(it);
}

void show_screen(Screen it, {ScreenTransition transition = ScreenTransition.fade_out_then_in}) {
  (game.world as ScreenNavigation).show_screen(it, transition: transition);
}
