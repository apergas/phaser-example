import 'package:flame/extensions.dart';

abstract final class CameraFraming {
  static Vector2 center({
    required Vector2 current,
    required Vector2 target,
    required Vector2 world,
    required Vector2 view,
    required double lerp,
  }) {
    return Vector2(
      _axis(current: current.x, target: target.x, world: world.x, view: view.x, lerp: lerp),
      _axis(current: current.y, target: target.y, world: world.y, view: view.y, lerp: lerp),
    );
  }

  static Vector2 snap(Vector2 center, double zoom) {
    return Vector2((center.x * zoom).roundToDouble() / zoom, (center.y * zoom).roundToDouble() / zoom);
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
