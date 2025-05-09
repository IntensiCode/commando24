import 'package:commando24/game/game_context.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

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
      log_info('proximity triggered');
      when_triggered();
      if (single_shot) {
        log_info('proximity removed');
        removeFromParent();
      }
    }
  }
}
