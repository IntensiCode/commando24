import 'package:commando24/game/entities/enemy.dart';
import 'package:commando24/game/entities/enemy_behavior.dart';
import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:commando24/game/player/player.dart';
import 'package:flame/components.dart';

class MovementRunsAcross extends Component with GameContext, EnemyBehavior, MovementMode {
  late Enemy enemy;
  late double x_dir;

  @override
  void attach(Enemy enemy) {
    this.x_dir = (my_prop.position.x < 160) ? 1 : -1;
    this.enemy = enemy;
    this.enemy.move_dir.x = x_dir;
    this.enemy.move_dir.y = 0;
    this.enemy.auto_fire_dir = false;
  }

  @override
  void offer_reaction() {
    if (enemy.move_dir.isZero()) {
      enemy.move_dir.x = -x_dir;
    }
    enemy.fire_dir.x = x_dir;
    enemy.fire_dir.y = (player.position.y - my_prop.position.y).sign;
  }
}
