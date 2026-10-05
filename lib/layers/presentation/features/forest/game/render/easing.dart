import 'dart:math' as math;

abstract final class Easing {
  static const double _backOvershoot = 1.70158;

  static double sineOut(double t) => math.sin(t * math.pi / 2);

  static double sineInOut(double t) => (1 - math.cos(math.pi * t)) / 2;

  static double quadIn(double t) => t * t;

  static double backOut(double t) {
    final shifted = t - 1;
    return shifted * shifted * ((_backOvershoot + 1) * shifted + _backOvershoot) + 1;
  }
}
