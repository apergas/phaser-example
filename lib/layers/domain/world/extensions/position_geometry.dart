import 'dart:math';

import '../../entities/geometry/position_entity.dart';

extension PositionGeometry on PositionEntity {
  double distanceTo(PositionEntity other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  PositionEntity moveTowards(PositionEntity target, double maxStep) {
    final distance = distanceTo(target);
    if (distance <= maxStep) return target;
    final ratio = maxStep / distance;
    return PositionEntity(x: x + (target.x - x) * ratio, y: y + (target.y - y) * ratio);
  }

  PositionEntity pointAtDistance(double distance, PositionEntity towards) {
    final length = distanceTo(towards);
    if (length == 0) return PositionEntity(x: x, y: y + distance);
    final ratio = distance / length;
    return PositionEntity(x: x + (towards.x - x) * ratio, y: y + (towards.y - y) * ratio);
  }
}
