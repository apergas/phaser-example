import 'easing.dart';

abstract final class GrowthMotion {
  static const double growMs = 600;
  static const double startScale = 0.35;

  static double scale(double elapsedMs) =>
      startScale + (1 - startScale) * Easing.backOut((elapsedMs / growMs).clamp(0, 1).toDouble());

  static bool hasGrown(double elapsedMs) => elapsedMs >= growMs;
}
