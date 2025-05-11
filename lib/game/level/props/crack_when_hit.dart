import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class CrackWhenHit extends Component {
  CrackWhenHit(this.cracks);

  final Sprite cracks;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_hit.add(() {
      // TODO pool and change color instead of stacking :-D
      my_prop.add(SpriteComponent(sprite: cracks, paint: pixel_paint()..color = shadow));
      soundboard.play(Sound.hit_crack);
    });
  }
}
