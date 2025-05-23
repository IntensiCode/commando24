import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_entities.dart';
import 'package:commando24/game/level/level_object.dart';
import 'package:commando24/game/player/player.dart';
import 'package:commando24/game/player/weapon_type.dart';
import 'package:commando24/util/component_recycler.dart';
import 'package:flame/components.dart';

class Projectile extends SpriteAnimationComponent with GameContext, Recyclable {
  Projectile(this.type, {this.hit_metal = true});

  final behaviors = <ProjectileBehavior>[];
  final data = <String, dynamic>{};

  final WeaponType type;
  final bool hit_metal;

  final velocity = Vector2.zero();

  void init({
    required SpriteAnimation animation,
    required Vector2 position,
    required Vector2 velocity,
  }) {
    this.animation = animation;
    this.position.setFrom(position);
    this.velocity.setFrom(velocity);
    this.anchor = Anchor.center;
    for (final it in behaviors) {
      it.init(this);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final it in behaviors) {
      it.update(this, dt);
    }
  }
}

abstract class ProjectileBehavior {
  void init(Projectile projectile) {}

  void update(Projectile projectile, double dt) {}

  void target_hit(Projectile projectile, LevelObject target) {}
}

class SetAngleFromVelocity extends ProjectileBehavior {
  static final _north = Vector2(0, 1);

  @override
  void init(Projectile projectile) {
    projectile.angle = projectile.velocity.angleTo(_north);
  }
}

class RecycleOnAnimComplete extends ProjectileBehavior {
  @override
  void init(Projectile projectile) {
    projectile.animationTicker?.reset();
    projectile.animationTicker?.onComplete = projectile.recycle;
  }
}

class MoveByVelocity extends ProjectileBehavior {
  @override
  void update(Projectile projectile, double dt) {
    projectile.position.add(projectile.velocity * dt);
    projectile.priority = projectile.position.y.toInt() + 16;
  }
}

class RecycleOutOfBounds extends ProjectileBehavior {
  @override
  void update(Projectile projectile, double dt) {
    if (projectile.position.x < -100) projectile.recycle();
    if (projectile.position.x > game_width + 100) projectile.recycle();
    if (projectile.position.y < projectile.player.y - game_height) projectile.recycle();
    if (projectile.position.y > projectile.player.y + game_height) projectile.recycle();
  }
}

class RecycleOnSolidHit extends ProjectileBehavior {
  static final _check_pos = Vector2.zero();

  @override
  void update(Projectile projectile, double dt) {
    _check_pos.setFrom(projectile.position);
    _check_pos.y += 6; // TODO wtf :-D ‾\_('')_/‾

    for (final solid in projectile.entities.solids) {
      if (solid.is_hit_by(_check_pos)) {
        if (solid.properties['walk_behind'] == true) continue;
        projectile.recycle();
        return;
      }
    }
  }
}

class RecycleOnTargetHit extends ProjectileBehavior {
  static final _check_pos = Vector2.zero();

  @override
  void update(Projectile projectile, double dt) {
    _check_pos.setFrom(projectile.position);
    _check_pos.y += 6;

    for (final target in projectile.entities.destructibles) {
      if (target.is_hit_by(_check_pos)) {
        target.on_hit(projectile.type);

        for (final it in projectile.behaviors) {
          it.target_hit(projectile, target);
        }

        if (projectile.hit_metal && target.properties['metal'] == true) {
          soundboard.play(Sound.hit_metal);
        }

        projectile.recycle();
        return;
      }
    }
  }
}
