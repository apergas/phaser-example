import '../../entities/geometry/obstacle_entity.dart';
import '../../entities/geometry/position_entity.dart';
import 'position_geometry.dart';

extension ObstacleRules on ObstacleEntity {
  bool blocks(PositionEntity position, double radius) => this.position.distanceTo(position) < this.radius + radius;
}
