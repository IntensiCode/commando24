import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/component_recycler.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

class Projectile extends SpriteAnimationComponent with Recyclable {
  Projectile(this.type, {this.hit_metal = true}) {
    logWarn('NEW PROJECTILE');
  }

  final WeaponType type;
  final bool hit_metal;

  final velocity = Vector2.zero();

  final _check_pos = Vector2.zero();

  void init({
    required SpriteAnimation animation,
    required Vector2 position,
    required Vector2 velocity,
  }) {
    this.animation = animation;
    this.position.setFrom(position);
    this.velocity.setFrom(velocity);
    this.anchor = Anchor.center;

    this.animationTicker?.reset();
    this.animationTicker?.onComplete = recycle;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(velocity * dt);

    if (position.x < -100) recycle();
    if (position.x > game_width + 100) recycle();
    if (position.y < player.y - game_height) recycle();
    if (position.y > player.y + game_height) recycle();

    priority = position.y.toInt() + 10;

    _check_pos.setFrom(position);
    _check_pos.y += 6;

    for (final it in model.solids) {
      if (it.is_hit_by(_check_pos)) {
        if (it.properties['walk_behind'] == true) continue;
        recycle();
        return;
      }
    }

    for (final it in model.destructibles) {
      if (it.is_hit_by(_check_pos)) {
        it.on_hit(type);

        if (hit_metal && it.properties['metal'] == true) {
          soundboard.play(Sound.hit_metal);
        }

        recycle();
        return;
      }
    }
  }
}
