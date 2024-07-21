import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../../core/common.dart';
import '../../util/auto_dispose.dart';
import '../../util/extensions.dart';
import '../../util/messaging.dart';
import '../../util/on_message.dart';
import '../../util/tiled_extensions.dart';
import '../game_context.dart';
import '../game_messages.dart';
import 'level_props.dart';
import 'level_state.dart';
import 'level_tiles.dart';

class Level extends PositionComponent with AutoDispose, GameContext, HasPaint {
  Level() {
    level = this;
    priority = -1000;
    paint = pixel_paint();
  }

  late final LevelTiles _tiles;
  late final LevelProps _big_props;
  late final LevelProps _small_props;

  int get level_number_starting_at_1 => model.state.level_number_starting_at_1;

  (int, TiledComponent)? _level_data;

  TiledMap? get map => _level_data?.$2.tileMap.map;

  String get name => map?.stringProperty('name') ?? '';

  var state = LevelState.waiting;

  double state_progress = 0.0;

  void reset() {
    state = LevelState.waiting;
    state_progress = 0;
    opacity = 0.0;
    _tiles.reset();
    _big_props.reset();
    _small_props.reset();
  }

  // Component

  @override
  Future onLoad() async {
    super.onLoad();

    await add(_tiles = LevelTiles(paint));
    await add(_big_props = LevelProps('props_big', 64, 64, paint));
    await add(_small_props = LevelProps('props_small', 32, 32, paint));

    onMessage<EnterRound>((_) {
      reset();
      preload_level();
    });
    onMessage<LoadLevel>((_) => _load_level());
  }

  Future<bool> preload_level() async {
    try {
      if (_level_data?.$1 != level_number_starting_at_1) {
        final which = level_number_starting_at_1.toString().padLeft(2, '0');
        final TiledComponent level_data = await TiledComponent.load('level$which.tmx', Vector2.all(16));
        _level_data = (level_number_starting_at_1, level_data);
      }
      return true;
    } catch (e) {
      logError('failed to load level $level_number_starting_at_1: $e');
      sendMessage(GameOver());
      return false;
    }
  }

  Future _load_level() async {
    logInfo('load level $level_number_starting_at_1');

    final ok = await preload_level();
    if (!ok) return;

    await _tiles.load(map!);
    await _big_props.load(map!);
    await _small_props.load(map!);

    sendMessage(LevelDataAvailable(map!));

    state = LevelState.appearing;
    state_progress = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case LevelState.waiting:
        break;
      case LevelState.appearing:
        _on_appearing(dt);
      case LevelState.active:
        _on_active(dt);
      case LevelState.defeated:
        break;
    }
  }

  void _on_appearing(double dt) {
    state_progress += dt * 2;
    if (state_progress >= 1.0) {
      state_progress = 1.0;
      state = LevelState.active;
      sendMessage(LevelReady());
      paint.opacity = 1;
    } else {
      paint.opacity = state_progress;
    }
  }

  void _on_active(double dt) {
    //
  }

  @override
  void renderTree(Canvas canvas) {
    if (state == LevelState.waiting) return;
    super.renderTree(canvas);
  }
}