import 'dart:ui';

abstract final class CameraFraming {
  static Offset center({
    required Offset current,
    required Offset target,
    required Size world,
    required Size view,
    required double lerp,
  }) {
    return Offset(
      _axis(current: current.dx, target: target.dx, world: world.width, view: view.width, lerp: lerp),
      _axis(current: current.dy, target: target.dy, world: world.height, view: view.height, lerp: lerp),
    );
  }

  static Offset snap(Offset center, double zoom) {
    return Offset((center.dx * zoom).roundToDouble() / zoom, (center.dy * zoom).roundToDouble() / zoom);
  }

  static double _axis({
    required double current,
    required double target,
    required double world,
    required double view,
    required double lerp,
  }) {
    if (view >= world) return world / 2;
    final next = current + (target - current) * lerp;
    return next.clamp(view / 2, world - view / 2).toDouble();
  }
}
