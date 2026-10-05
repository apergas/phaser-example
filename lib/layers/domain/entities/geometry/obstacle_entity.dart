import 'position_entity.dart';

class ObstacleEntity {
  final PositionEntity position;
  final double radius;

  const ObstacleEntity({required this.position, required this.radius}) : assert(radius > 0);

  @override
  bool operator ==(Object other) => other is ObstacleEntity && other.position == position && other.radius == radius;

  @override
  int get hashCode => Object.hash(position, radius);
}
