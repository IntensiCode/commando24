import 'package:commando24/core/atlas.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/level/props/level_prop.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

extension GameContextExtensions on GameContext {
  Decals get decals => cache.putIfAbsent('decals', () => Decals());
}

class Decals extends Component with GameContext {
  Decals() {
    _sprites32 = atlas.sheetIWH('tileset', 32, 32);
  }

  late final SpriteSheet _sprites32;

  void spawn_for(LevelProp prop) {
    final big = prop.hit_width > 16;
    final which = prop.enemy != null
        ? 194
        : big
            ? 192
            : 193;
    final sprite = _sprites32.getSpriteById(which);
    entities.add(SpriteComponent(
      sprite: sprite,
      anchor: Anchor.bottomCenter,
      position: prop.position,
      priority: prop.position.y.toInt() - 15,
    ));
  }
}
