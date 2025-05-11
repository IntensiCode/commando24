import 'dart:async';

import 'package:commando24/core/common.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/util/bitmap_text.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/messaging.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';

class ShowDebugText with Message {
  ShowDebugText({this.title, required this.text, this.when_done});

  String? title;
  final String text;
  final Function? when_done;
}

extension ComponentExtensions on Component {
  void show_debug(String text, {String? title, Function? done}) {
    send_message(ShowDebugText(title: title, text: text, when_done: done));
  }
}

class DebugOverlay extends GameScriptComponent {
  DebugOverlay() {
    add(_instance = _DebugOverlay(pos_y: 16, quick: true));
    priority = 10000;
  }

  late _DebugOverlay _instance;

  @override
  void onMount() {
    super.onMount();
    on_message<ShowDebugText>((it) => _instance.pipe.add(it..title = null));
  }
}

class _DebugOverlay extends GameScriptComponent {
  _DebugOverlay({required this.pos_y, this.quick = true});

  final pipe = <ShowDebugText>[];

  final double pos_y;
  final bool quick;

  Future? _active;

  late final BitmapText _title_text;
  late final BitmapText _text;

  @override
  onLoad() {
    font_select(tiny_font, scale: 1);
    _title_text = added(textXY('', game_width / 2, pos_y - 15, scale: 2)..isVisible = false);
    _text = added(textXY('', game_width / 2, pos_y + 5)..isVisible = false);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_active != null || pipe.isEmpty) return;

    final it = pipe.first;

    script_clear();

    script_after(0.0, () {
      _title_text.isVisible = it.title != null;
      _title_text.change_text_in_place(it.title ?? '');
      if (it.title != null) _title_text.fadeInDeep();

      _text.isVisible = true;
      _text.change_text_in_place(it.text);
      _text.fadeInDeep();
    });
    // if (kReleaseMode && it.stay_longer) script_after(2, () {});
    if (pipe.length > 3) {
      script_after(0.4, () => _text.fadeOutDeep(and_remove: false));
      script_after(0.0, () {
        if (it.title != null) _title_text.fadeOutDeep(and_remove: false);
      });
      script_after(0.4, () => it.when_done?.call());
    } else {
      // script_after(quick ? 0.2 : 0.4, () {
      //   if (it.blink_text) _text.add(BlinkEffect(on: 0.35, off: 0.15));
      // });
      script_after(quick ? 0.9 : 1.8, () => _text.removeAll(_text.children)); // remove blink?
      if (pipe.length == 1) {
        script_after(quick ? 0.0 : 1.0, () => _text.fadeOutDeep(and_remove: false));
        script_after(0.0, () {
          if (it.title != null) _title_text.fadeOutDeep(and_remove: false);
        });
        script_after(quick ? 0.2 : 0.5, () => it.when_done?.call());
      } else {
        script_after(0.0, () => it.when_done?.call());
      }
    }

    final active = _active = script_execute();
    _active?.then((_) {
      pipe.removeAt(0);
      if (_active == active) _active = null;
    });
  }
}
