import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

import '../../core/common.dart';
import '../../util/extensions.dart';
import '../../util/functions.dart';
import '../../util/tiled_extensions.dart';
import '../game_context.dart';
import 'level_object_base.dart';

class LevelTiles extends Component with GameContext, HasVisibility {
  LevelTiles(this._paint);

  final Paint _paint;

  final _cached_tiles = <List<List<Gid>>>[];
  final _cached_priority = <int, int>{};
  final _cached_rect = <int, Rect>{};
  final _cached_transforms = <int, RSTransform>{};
  final _render_pos = Vector2.zero();

  late final SpriteSheet _sprites;
  late final SpriteBatch _batch;

  late TiledMap? _map;

  void reset() => _map = null;

  Future load(TiledMap map) async {
    _map = map;
    _cached_tiles.clear();

    final which = map.layers.whereType<TileLayer>();
    for (final it in which) {
      final tiles = it.tileData;
      if (tiles != null) _cached_tiles.add(tiles);
    }

    final tileset = _map!.tilesetByName('tileset');

    for (var y = 0; y < map.height; y++) {
      final row_index = _map!.height - y - 1;
      if (row_index < 0) continue;

      final map_width = _map!.width;
      for (var x = 0; x < map_width; x++) {
        _render_pos.setValues(x * 16, (16 - y - 1) * 16);

        for (var t = 0; t < _cached_tiles.length; t++) {
          if (t == 0) continue;

          final tiles = _cached_tiles[t];
          final row = tiles[row_index];
          final gid = row[x];
          if (gid.tile == 0) continue;

          final index = (gid.tile - tileset.firstGid!).clamp(0, tileset.tileCount! - 1);
          final priority = _cached_priority[gid.tile] ??= tileset.priority(gid.tile - 1);
          await model.add(_StackedTile(
            sprite: _sprites.getSpriteById(index),
            paint: _paint,
            position: _render_pos,
            priority: _render_pos.y.toInt() + t * 16 - 16 + priority,
          ));
        }
      }
    }
  }

  @override
  bool get isVisible => _map != null;

  @override
  Future onLoad() async {
    super.onLoad();
    final atlas = await image('tileset.png');
    _sprites = sheetWH(atlas, 16, 16);
    _batch = SpriteBatch(atlas, useAtlas: !kIsWeb);
  }

  @override
  void render(Canvas canvas) {
    if (_map == null) return;
    super.render(canvas);

    final stacking = List.generate(_cached_tiles.length, (_) => _Stacking());

    final tileset = _map!.tilesetByName('tileset');

    final int off = (game.camera.visibleWorldRect.top / 16).abs().toInt();
    for (var y = off + 15; y >= off; y--) {
      final row_index = _map!.height - y - 1;
      if (row_index < 0) continue;

      final map_width = _map!.width;
      for (var x = 0; x < map_width; x++) {
        for (var t = 0; t < _cached_tiles.length; t++) {
          final tiles = _cached_tiles[t];
          final row = tiles[row_index];
          final gid = row[x];
          if (gid.tile == 0) continue;

          final s = stacking[t];
          s.priority = _cached_priority[gid.tile] ??= tileset.priority(gid.tile - 1);
          if (s.priority > 0) continue;

          s.rect = _cached_rect[gid.tile] ??= tileset.rect(gid.tile - 1);
        }

        stacking.sort((a, b) => a.priority - b.priority);

        _render_pos.setValues(x * 16, (15 - y - 1) * 16);
        for (final it in stacking) {
          if (it.rect != null) {
            final trans = _cached_transforms[x + y * map_width] ??= _render_pos.transform;
            _batch.addTransform(source: it.rect!, transform: trans);
          }
          it.priority = 0;
          it.rect = null;
        }
      }
    }
    _batch.render(canvas, paint: _paint);
    _batch.clear();
  }
}

class _Stacking {
  int priority = 0;
  Rect? rect;
}

class _StackedTile extends SpriteComponent with HasVisibility, LevelObjectBase {
  _StackedTile({
    required super.sprite,
    required Paint paint,
    required super.position,
    required super.priority,
  }) : super(anchor: Anchor.bottomCenter) {
    level_paint = paint;
    position.x += width / 2;
    override_width = 32;
    override_height = 24;
  }
}
