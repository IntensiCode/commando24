import 'dart:ui';

import 'package:flame/components.dart';

PostProcess? game_post_process;

mixin PostProcess on Component {
  bool active = true;

  void post_process(Canvas canvas, Function(Canvas) render);
}

class PostFxScreenHolder extends Component {
  @override
  void update(double dt) {
    super.update(dt);
    game_post_process?.update(dt);
    if (game_post_process?.active == false) {
      game_post_process = null;
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (game_post_process != null) {
      game_post_process?.post_process(canvas, super.renderTree);
    } else {
      super.renderTree(canvas);
    }
  }
}
