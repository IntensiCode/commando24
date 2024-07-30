import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/soundboard.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/on_message.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Prisoners extends Component with AutoDispose {
  static final _temp_pos = Vector2.zero();

  Prisoners(this._sprites1632);

  final SpriteSheet _sprites1632;

  @override
  void onMount() {
    super.onMount();
    onMessage<LevelDataAvailable>((it) {
      final layer = it.map.layerByName('prisoners_atlas') as ObjectGroup;
      for (final object in layer.objects) {
        logInfo(object.position);
        _temp_pos.setValues(object.x, (15 - it.map.height) * 16 + object.y);
        entities.add(Prisoner(_temp_pos, _sprites1632));
      }
    });
  }
}

class Prisoner extends SpriteAnimationComponent {
  Prisoner(Vector2 position, this._sprites1632) : super(position: position, anchor: Anchor.bottomCenter) {
    animation = _sprites1632.createAnimation(row: 24, stepTime: 0.1, from: 33, to: 34);
    priority = position.y.toInt() + 2;
    super.position.x += 8;
  }

  final SpriteSheet _sprites1632;

  double _run_speed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_run_speed == 0) {
      final close_x = (player.position.x - position.x).abs() < 12;
      final close_y = (player.position.y - position.y).abs() < 12;
      if (close_x && close_y) {
        soundboard.play(Sound.prisoner_freed);
        if (position.x >= 160) {
          _run_speed = 100;
          animation = _sprites1632.createAnimation(row: 24, stepTime: 0.1, from: 24, to: 29);
        } else {
          _run_speed = -100;
          animation = _sprites1632.createAnimation(row: 24, stepTime: 0.1, from: 29, to: 34);
        }
      }
    } else {
      position.x += _run_speed * dt;
    }
  }
}
