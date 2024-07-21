import 'dart:math';

import 'package:flame/components.dart';

class MutRect {
  double x = 0;
  double y = 0;
  double width = 0;
  double height = 0;

  MutRect();

  MutRect.xy(this.x, this.y);

  MutRect.xy_wh(this.x, this.y, this.width, this.height);

  MutRect.copy(MutRect other) : this.xy_wh(other.x, other.y, other.width, other.height);

  MutRect.center_and_size(Vector2 center, Vector2 size) {
    setCenterAndSize(center, size);
  }

  MutRect.position_and_size(Vector2 position, Vector2 size) {
    set(position, size);
  }

  void set(Vector2 aPosition, Vector2 aSize) {
    x = aPosition.x;
    y = aPosition.y;
    width = aSize.x;
    height = aSize.y;
  }

  void setFrom(MutRect aRectangle) {
    x = aRectangle.x;
    y = aRectangle.y;
    width = aRectangle.width;
    height = aRectangle.height;
  }

  void applyOutsets(double aOutsetSizeInPixels) {
    x -= aOutsetSizeInPixels;
    y -= aOutsetSizeInPixels;
    width += aOutsetSizeInPixels * 2;
    height += aOutsetSizeInPixels * 2;
  }

  void setCenterAndSize(Vector2 aPosition, Vector2 aSize) {
    setCenterWH(aPosition, aSize.x, aSize.y);
  }

  void setCenterWH(Vector2 aPosition, double aWidth, double aHeight) {
    width = aWidth;
    height = aHeight;
    x = aPosition.x - width / 2;
    y = aPosition.y - height / 2;
  }

  bool contains(Vector2 xy) {
    if (xy.x < x || xy.x > x + width) return false;
    if (xy.y < y || xy.y > y + height) return false;
    return true;
  }

  bool containsXY(double aX, double aY) {
    if (aX < x || aX > x + width) return false;
    if (aY < y || aY > y + height) return false;
    return true;
  }

  bool intersectsWith(MutRect other) {
    final x1 = other.x;
    final x2 = other.x + other.width;
    if (x > x2 || x + width < x1) return false;
    final y1 = other.y;
    final y2 = other.y + other.height;
    if (y > y2 || y + height < y1) return false;
    return true;
  }

  bool isAdjacent(MutRect other) {
    if (x == other.x && width == other.width) {
      if (y == other.y + other.height) return true;
      if (y + height == other.y) return true;
    }
    if (y == other.y && height == other.height) {
      if (x == other.x + other.width) return true;
      if (x + width == other.x) return true;
    }
    return false;
  }

  void extendWith(MutRect that) {
    final left = min(x, that.x);
    final top = min(y, that.y);
    final right = max(x + width, that.x + that.width);
    final bottom = max(y + height, that.y + that.height);
    x = left;
    y = top;
    width = right - left;
    height = bottom - top;
  }
}
