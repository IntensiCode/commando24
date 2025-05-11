import 'common.dart';

enum Screen {
  audio_menu,
  credits,
  enter_hiscore,
  game,
  help,
  hiscore,
  options,
  splash,
  the_end,
  title,
}

class ShowScreen with Message {
  ShowScreen(this.screen);

  final Screen screen;
}

abstract interface class ScreenNavigation {
  void pop_screen();

  void push_screen(Screen screen);

  void show_screen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false});
}

void pop_screen() {
  final world = game.world;
  (world as ScreenNavigation).pop_screen();
}

void push_screen(Screen it) {
  final world = game.world;
  (world as ScreenNavigation).push_screen(it);
}

void show_screen(Screen it, {bool skip_fade_out = false, bool skip_fade_in = false}) {
  final world = game.world;
  (world as ScreenNavigation).show_screen(it, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
}
