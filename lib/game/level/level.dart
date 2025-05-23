import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/game_state.dart';
import 'package:commando24/game/level/level_props.dart';
import 'package:commando24/game/level/level_state.dart';
import 'package:commando24/game/level/level_tiles.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/log.dart';
import 'package:commando24/util/on_message.dart';
import 'package:commando24/util/tiled_extensions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

extension GameContextExtensions on GameContext {
  Level get level => cache.putIfAbsent('level', () => Level());
}

class Level extends PositionComponent with AutoDispose, GameContext, HasPaint {
  Level() {
    priority = -1000;
    paint = pixel_paint();
  }

  late final SpriteSheet _sprites16;
  late final LevelTiles _tiles;
  late final LevelProps _big_props;
  late final LevelProps _small_props;
  late final LevelProps _prisoners;
  late final LevelProps _enemies;

  int get level_number_starting_at_1 => game_state.level_number_starting_at_1;

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
    _prisoners.reset();
  }

  List<List<Gid>>? _advice;

  final _advice_dir = Vector2.zero();

  Vector2? advice_for(Vector2 position) {
    _advice ??= (map?.layerByName('advice') as TileLayer?)?.tileData;

    final it = _advice;
    if (it == null) return null;

    final x = position.x ~/ 16;
    if (x < 0 || x >= map!.width) return null;

    final y = (position.y - (15 - map!.height) * 16) ~/ 16;
    if (y < 0 || y >= map!.height) return null;

    _advice_dir.setZero();
    final advice = it[y][position.x ~/ 16];
    if (advice.tile == 607) _advice_dir.x = 1;
    if (advice.tile == 608) _advice_dir.x = -1;
    if (advice.tile == 609) _advice_dir.y = -1;
    if (advice.tile == 610) _advice_dir.y = 1;
    return _advice_dir.isZero() ? null : _advice_dir;
  }

  // Component

  @override
  Future onLoad() async {
    super.onLoad();

    _sprites16 = atlas.sheetIWH('tileset', 16, 16);
    await add(_tiles = LevelTiles(_sprites16, paint));
    await add(_big_props = LevelProps('props_big', 64, 64, paint));
    await add(_small_props = LevelProps('props_small', 32, 32, paint));
    await add(_prisoners = LevelProps('prisoners', 16, 32, paint));
    await add(_enemies = LevelProps('enemies', 16, 32, paint));

    _prisoners.tileset_override = 'characters';
    _enemies.tileset_override = 'characters';

    on_message<EnterRound>((_) {
      reset();
      preload_level();
    });
    on_message<LoadLevel>((_) => _load_level());
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
      log_error('failed to load level $level_number_starting_at_1: $e');
      send_message(GameOver());
      return false;
    }
  }

  Future _load_level() async {
    log_info('load level $level_number_starting_at_1');

    final ok = await preload_level();
    if (!ok) return;

    await _tiles.load(map!);
    await _big_props.load(map!);
    await _small_props.load(map!);
    await _prisoners.load(map!);
    await _enemies.load(map!);

    send_message(LevelDataAvailable(map!));

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
      send_message(LevelReady());
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
