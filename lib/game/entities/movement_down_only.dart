import 'package:commando24/game/entities/enemy.dart';
import 'package:commando24/game/entities/enemy_behavior.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class MovementDownOnly extends Component with MovementMode, EnemyBehavior {
  late Enemy enemy;

  @override
  void attach(Enemy enemy) => this.enemy = enemy;

  @override
  void offer_reaction() {
    enemy.move_dir.x = (player.position.x - my_prop.position.x).sign;
    enemy.move_dir.y = 1;
  }
}
