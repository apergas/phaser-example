abstract final class RenderDepth {
  static const int ground = -2000000;
  static const int shadow = -1000000;
  static const int overlay = 1000000000;

  static int bySortY(double baseY) => (baseY * 100).round();
}
