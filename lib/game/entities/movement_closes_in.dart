import 'package:commando24/game/entities/enemy.dart';
import 'package:commando24/game/entities/enemy_behavior.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/path_finder.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/player/player.dart';
import 'package:flame/components.dart';

class MovementClosesIn extends Component with GameContext, EnemyBehavior, MovementMode {
  late Enemy enemy;

  @override
  void attach(Enemy enemy) {
    this.enemy = enemy;
    this.enemy.use_advice = false;
  }

  final _path_segment = List.generate(5, (_) => Vector2.all(double.nan));

  @override
  void offer_reaction() {
    // Finding an entirely new path is reaction based:
    if (_path_segment.first.isNaN) {
      path_finder.find_path_to_player(my_prop, _path_segment);
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    path_finder.debug_paths.remove(_path_segment);
  }

  @override
  void update(double dt) {
    super.update(dt);

    enemy.fire_dir.setFrom(player.position);
    enemy.fire_dir.sub(my_prop.position);

    // If player is close, stop. For now. Really needs FindsCover behavior instead.
    final dist = enemy.fire_dir.normalize();
    if (dist < 32) return;

    // Nowhere to go?
    if (_path_segment.first.isNaN) return;

    // Reached current target segment?
    if (my_prop.position.distanceToSquared(_path_segment.first) < 16) {
      // Set next target segment:
      for (var i = 1; i < _path_segment.length; i++) {
        _path_segment[i - 1].setFrom(_path_segment[i]);
      }
      _path_segment.last.setAll(double.nan);

      // If path is ending, see if there is more:
      if (_path_segment[1].isNaN) {
        path_finder.find_path_to_player(my_prop, _path_segment);
      }
    } else {
      // Move further into current target segment:
      _temp.setFrom(_path_segment.first);
      _temp.sub(my_prop.position);
      _temp.normalize();
      _temp.scale(configuration.enemy_move_speed * dt);
      my_prop.position.add(_temp);
    }
  }

  final _temp = Vector2.zero();
}
