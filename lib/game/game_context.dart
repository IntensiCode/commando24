import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_phase.dart';
import 'package:commando24/game/game_screen.dart';
import 'package:commando24/game/stage_cache.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/util/messaging.dart';
import 'package:flame/components.dart';

/// Easy access to all primary components via GameScreen -> StageCache.
/// Primary components are expected to provide an extension on GameContext.
/// Direct cache access is discouraged for component access.
mixin GameContext on Component {
  GameScreen? _stage;

  GameScreen get stage => _stage ??= findParent<GameScreen>(includeSelf: true)!;

  StageCache get cache => stage.stage_cache;

  GamePhase get phase => stage.phase;

  Keys get keys => stage.stage_keys;

  Messaging get _messaging => cache.putIfAbsent('messaging', () => stage.messaging);

  void send_message<T extends Message>(T message) => _messaging.send(message);

  @override
  void onMount() {
    super.onMount();
    stage; // to fix remove and re-mount scenarios (collectibles)
  }
}
