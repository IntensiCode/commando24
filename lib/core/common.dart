import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef Check = bool Function();
typedef Hook = void Function();

Vector2 v2([double x = 0, double y = 0]) => Vector2(x, y);

Vector2 v2z() => Vector2.zero();

Function(bool)? on_debug_change;

bool _debug = kDebugMode && !kIsWeb;

bool get debug => _debug;

set debug(bool value) {
  _debug = value;
  on_debug_change?.call(value);
  game.debugMode = value;
  for (final it in game.descendants()) {
    it.debugMode = value;
  }
}

bool dev = kDebugMode;

bool cheat = dev;

const tps = 60;

const double game_width = 320;
const double game_height = 240;
final Vector2 game_size = Vector2(game_width, game_height);
final Vector2 game_center = game_size / 2;

const line_height = game_height / 20;

const center_x = game_width / 2;
const center_y = game_height / 2;

late FlameGame game;
late Images images;

// to avoid importing materials elsewhere (which causes clashes sometimes), some color values right here

const black = Color(0xFF000000);
const blue = Color(0xFF0000ff);
const cyan = Color(0xFF00ffff);
const green = Color(0xFF00ff00);
const magenta = Color(0xFFff00ff);
const orange = Color(0xFFff8000);
const red = Color(0xFFff0000);
const white = Color(0xFFffffff);
const yellow = Color(0xFFffff00);

const shadow = Color(0x80000000);
const shadow_dark = Color(0xC0000000);
const shadow_soft = Color(0x40000000);
const transparent = Colors.transparent;

Paint pixel_paint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

mixin Message {}

class MouseWheel with Message {
  final double direction;

  MouseWheel(this.direction);
}

TODO(String message) => throw UnimplementedError(message);
