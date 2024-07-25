import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:commando24/game/game_context.dart';
import 'package:commando24/game/game_messages.dart';
import 'package:commando24/game/player/player_state.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/fonts.dart';
import 'package:commando24/util/functions.dart';
import 'package:commando24/util/on_message.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class WeaponsHud extends PositionComponent with AutoDispose, HasPaint {
  WeaponsHud(this._sprites32);

  final SpriteSheet _sprites32;

  late final Sprite _slot;

  final _render_pos = Vector2.zero();

  double _blink_time = 0;

  @override
  FutureOr<void> onLoad() async {
    _slot = await sprite('weapon_slot.png');

    onMessage<WeaponPickedUp>((it) {});
    onMessage<WeaponSwitched>((it) {});

    paint.opacity = 0;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (paint.opacity < 1 && player.state == PlayerState.playing) {
      paint.opacity += min(1 - paint.opacity, dt * 4);
    }
    if (paint.opacity > 0 && player.state != PlayerState.playing) {
      paint.opacity -= min(paint.opacity, dt * 4);
    }
    _blink_time += dt;
    if (_blink_time > 1) _blink_time -= 1;
  }

  // TODO snapshot

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (paint.opacity == 0) return;
    // if (player.state != PlayerState.playing) return;

    _render_pos.x = 0;
    for (final it in model.weapons.weapons.values) {
      final show_text = it != player.active_weapon || _blink_time < 0.8;
      if (show_text) {
        tiny_font.paint = paint;
        tiny_font.drawStringAligned(canvas, _render_pos.x + 16, 212, (it.type.index + 1).toString(), Anchor.center);
      }

      if (it.ammo != 0) {
        _render_pos.y = 240 - 26;
        _slot.render(canvas, position: _render_pos, overridePaint: paint);
      }

      _render_pos.y = 240 - 41;
      final sprite = _sprites32.getSprite(17, it.type.index);
      sprite.render(canvas, position: _render_pos, overridePaint: paint);

      if (show_text) {
        final x = _render_pos.x + 16;
        final y = _render_pos.y + 36;
        final ammo = it.ammo == -1 ? '\u0080' : it.ammo.toString();
        tiny_font.paint = paint;
        tiny_font.drawStringAligned(canvas, x, y, ammo, Anchor.center);
      }

      if (it.ammo == 0) {
        _render_pos.y = 240 - 26;
        _slot.render(canvas, position: _render_pos, overridePaint: paint);
      }

      _render_pos.x += 32;
    }
  }
}
