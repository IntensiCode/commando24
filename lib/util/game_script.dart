import 'dart:async';

import 'auto_dispose.dart';
import 'game_script_functions.dart';

class GameScriptComponent extends AutoDisposeComponent with GameScriptFunctions, GameScript {}

mixin GameScript on GameScriptFunctions {
  var _script = <(double, Function())>[];
  double? _active_delay;

  void script_clear() {
    _script = [];
    _active_delay = null;
  }

  void pause_script(double deltaSeconds) => script_after(deltaSeconds, () {});

  void script_after(double deltaSeconds, Function() execute) => _script.add((deltaSeconds, execute));

  Future script_execute() {
    final result = Completer();
    script_after(0.0, () => result.complete());
    return result.future;
  }

  @override
  void onMount() {
    super.onMount();
    script_execute();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _active_delay ??= _script.firstOrNull?.$1;
    if (_active_delay == null) return;

    final ad = _active_delay = _active_delay! - dt;
    if (ad > 0) return;
    _active_delay = null;

    final it = _script.removeAt(0);
    it.$2();
  }
}
