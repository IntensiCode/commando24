import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../../core/common.dart';
import '../../util/functions.dart';
import '../game_context.dart';
import 'level_object_base.dart';

class LevelProps extends Component with GameContext, HasVisibility {
  LevelProps(this._name, this._width, this._height, this._paint);

  final String _name;
  final int _width;
  final int _height;
  final Paint _paint;

  late final SpriteSheet _sprites;

  TiledMap? _map;

  void reset() {
    _map = null;
    model.removeAll(model.children.whereType<LevelProp>());
  }

  Future load(TiledMap map) async {
    _map = map;

    final tileset = _map!.tilesetByName(_name);
    final props = _map!.layerByName(_name) as ObjectGroup;
    final pos = Vector2.zero();
    for (final it in props.objects) {
      final priority = it.properties.byName['priority'] as IntProperty?;
      var width = (it.properties.byName['width'] as IntProperty?)?.value;
      var height = (it.properties.byName['height'] as IntProperty?)?.value;

      final index = (it.gid! - tileset.firstGid!).clamp(0, tileset.tileCount! - 1);

      final tile = tileset.tiles[index];
      width ??= (tile.properties.byName['width'] as IntProperty?)?.value;
      height ??= (tile.properties.byName['height'] as IntProperty?)?.value;

      final merged_properties = <String, Object>{};
      for (final it in it.properties.byName.entries) {
        merged_properties[it.key] = it.value.value;
      }
      for (final it in tile.properties.byName.entries) {
        merged_properties[it.key] ??= it.value.value;
      }
      if (tile.type != null) {
        merged_properties['type'] = tile.type!;
      }

      pos.setValues(it.x, (15 - _map!.height) * 16 + it.y);

      final prop = LevelProp(
        sprite: _sprites.getSpriteById(index),
        paint: _paint,
        position: pos,
        priority: pos.y.toInt() + (priority?.value ?? 0),
      );
      prop.properties = merged_properties;
      prop.override_width = width?.toDouble();
      prop.override_height = height?.toDouble();

      await model.add(prop);
    }
    //
    // // final potentials = model.children.whereType<LevelProp>();//.where((it) => it.properties['spawn_prop'] == true);
    // logInfo(potentials);
    // logInfo(model.children.length);
    // for (final consumable in attach_for_spawn) {
    //   logInfo(consumable);
    //   if (dev) {
    //     final matches = potentials.where((it) {
    //       logInfo('check $it');
    //       final d = it.center.distanceToSquared(consumable.center);
    //       logInfo(d);
    //       return d < 100;
    //     });
    //     if (matches.length != 1) {
    //       throw 'expected 1 match, got $matches';
    //     }
    //   }
    //   final container = potentials.firstWhere((it) => it.position.distanceToSquared(consumable.position) < 100);
    //   container.properties['consumable'] = consumable;
    // }
  }

  @override
  bool get isVisible => _map != null;

  @override
  Future onLoad() async {
    super.onLoad();
    _sprites = await sheetIWH('$_name.png', _width, _height);
  }

  @override
  void renderTree(Canvas canvas) {
    if (_map == null) return;
    super.renderTree(canvas);
  }
}

class LevelProp extends SpriteComponent with HasVisibility, LevelObjectBase {
  LevelProp({
    required super.sprite,
    required Paint paint,
    required super.position,
    required super.priority,
  }) : super(anchor: Anchor.bottomCenter) {
    level_paint = paint;
    position.x += width / 2;
  }

  @override
  void onMount() {
    super.onMount();
    if (properties['spawn_when_close'] == true) _replace_with_proximity_sensor();
    if (properties['spawned'] == true) _move_into_container();
  }

  void _replace_with_proximity_sensor() {
    properties.remove('spawn_when_close');

    model.add(ProximitySensor(
      center: center,
      radius: 32,
      when_triggered: () => model.add(this),
    ));

    removeFromParent();
  }

  void _move_into_container() {
    final containers = model.children.whereType<LevelProp>();
    for (final it in containers) {
      if (it.containsPoint(center)) {
        logInfo(it);
        it.properties['consumable'] = this;
        removeFromParent();
        return;
      }
    }

    if (dev) {
      throw 'could not find container for $this in $containers';
    } else {
      logError('could not find container for $this in $containers');
    }
  }

  @override
  String toString() => '$properties at $position';
}

extension TiledObjectExtensions on TiledObject {
  int get priority => properties.firstWhere((it) => it.name == 'priority').value as int;
}

class ProximitySensor extends Component {
  ProximitySensor({
    required this.center,
    required this.radius,
    required this.when_triggered,
    this.single_shot = true,
  });

  final Vector2 center;
  final double radius;
  final Function when_triggered;
  final bool single_shot;

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoved || isRemoving) return;

    if (player.center.distanceToSquared(center) < radius * radius) {
      logInfo('proximity triggered');
      when_triggered();
      if (single_shot) {
        logInfo('proximity removed');
        removeFromParent();
      }
    }
  }
}
