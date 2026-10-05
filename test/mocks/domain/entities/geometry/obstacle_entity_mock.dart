import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

abstract final class ObstacleEntityMock {
  static const ObstacleEntity mock = ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

  static const ObstacleEntity treeTrunk = ObstacleEntity(position: PositionEntity(x: 200, y: 100), radius: 10);

  static const ObstacleEntity houseFootprint = ObstacleEntity(position: PositionEntity(x: 0, y: 0), radius: 40);

  static ObstacleEntity make({double radius = 10}) =>
      ObstacleEntity(position: const PositionEntity(x: 30, y: 0), radius: radius);
}
