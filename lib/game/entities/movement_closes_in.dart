import 'package:commando24/game/entities/enemy.dart';
import 'package:commando24/game/entities/enemy_behavior.dart';
import 'package:commando24/game/game_configuration.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class MovementClosesIn extends Component with EnemyBehavior, MovementMode {
  late Enemy enemy;

  @override
  void attach(Enemy enemy) {
    this.enemy = enemy;
    this.enemy.use_advice = false;
  }

  final _path_segment = List.generate(10, (_) => Vector2.all(double.nan));

  @override
  void offer_reaction() {
    // Finding an entirely new path is reaction based:
    if (_path_segment.first.isNaN) {
      model.path_finder.find_path_to_player(my_prop, _path_segment);
    }
  }

  final _temp = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);

    enemy.fire_dir.setFrom(player.position);
    enemy.fire_dir.sub(my_prop.position);

    final dist = enemy.fire_dir.normalize();
    if (dist < 32) {
      return;
    }

    if (_path_segment.first.isNaN) {
      return;
    }

    if (my_prop.position.distanceToSquared(_path_segment.first) < 16) {
      // Set next target segment:
      for (var i = 1; i < _path_segment.length; i++) {
        _path_segment[i - 1].setFrom(_path_segment[i]);
      }
      _path_segment.last.setAll(double.nan);

      // If path is ending, see if there is more:
      if (_path_segment[1].isNaN) {
        model.path_finder.find_path_to_player(my_prop, _path_segment);
      }
    } else {
      // Move into current target segment:
      _temp.setFrom(_path_segment.first);
      _temp.sub(my_prop.position);
      _temp.normalize();
      _temp.scale(configuration.enemy_move_speed * dt);
      my_prop.position.add(_temp);
    }
  }
}
