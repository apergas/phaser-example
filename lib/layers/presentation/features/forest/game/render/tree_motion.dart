import 'dart:math' as math;

import 'easing.dart';

abstract final class TreeMotion {
  static const double shakeDegrees = 3;
  static const double shakeHalfMs = 70;
  static const double shakeMs = shakeHalfMs * 2;
  static const double fallDegrees = 85;
  static const double fallMs = 700;

  static double direction({required double fromX, required double baseX}) => fromX < baseX ? 1 : -1;

  static double shakeAngle({required double elapsedMs, required double direction}) {
    if (elapsedMs < 0 || elapsedMs >= shakeMs) return 0;
    final leg = elapsedMs < shakeHalfMs ? elapsedMs / shakeHalfMs : (shakeMs - elapsedMs) / shakeHalfMs;
    return _radians(shakeDegrees * direction * Easing.sineOut(leg));
  }

  static double fallAngle({required double elapsedMs, required double direction}) {
    return _radians(fallDegrees * direction * _fallProgress(elapsedMs));
  }

  static double fallOpacity(double elapsedMs) => 1 - _fallProgress(elapsedMs);

  static bool hasFallen(double elapsedMs) => elapsedMs >= fallMs;

  static double _fallProgress(double elapsedMs) => Easing.quadIn((elapsedMs / fallMs).clamp(0, 1).toDouble());

  static double _radians(double degrees) => degrees * math.pi / 180;
}
