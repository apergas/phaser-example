import 'easing.dart';

abstract final class RockMotion {
  static const double shakeOffset = 1.5;
  static const double shakeHalfMs = 60;
  static const double shakeMs = shakeHalfMs * 2;
  static const double breakMs = 350;
  static const double breakEndScale = 0.6;

  static double direction({required double fromX, required double baseX}) => fromX < baseX ? 1 : -1;

  static double shakeX({required double elapsedMs, required double direction}) {
    if (elapsedMs < 0 || elapsedMs >= shakeMs) return 0;
    final leg = elapsedMs < shakeHalfMs ? elapsedMs / shakeHalfMs : (shakeMs - elapsedMs) / shakeHalfMs;
    return shakeOffset * direction * Easing.sineOut(leg);
  }

  static double breakScale(double elapsedMs) => 1 - (1 - breakEndScale) * _breakProgress(elapsedMs);

  static double breakOpacity(double elapsedMs) => 1 - _breakProgress(elapsedMs);

  static bool hasBroken(double elapsedMs) => elapsedMs >= breakMs;

  static double _breakProgress(double elapsedMs) => Easing.quadIn((elapsedMs / breakMs).clamp(0, 1).toDouble());
}
