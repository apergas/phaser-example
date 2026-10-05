import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';
import 'blueprint_entity.dart';

class BuildingEntity {
  final String id;
  final BlueprintEntity blueprint;
  final PositionEntity position;
  final int hitsDone;

  const BuildingEntity({required this.id, required this.blueprint, required this.position, this.hitsDone = 0});

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: blueprint.footprintRadius);

  double get progress => hitsDone / blueprint.hitsToBuild;

  bool get isComplete => hitsDone >= blueprint.hitsToBuild;

  BuildingEntity copyWith({String? id, BlueprintEntity? blueprint, PositionEntity? position, int? hitsDone}) {
    return BuildingEntity(
      id: id ?? this.id,
      blueprint: blueprint ?? this.blueprint,
      position: position ?? this.position,
      hitsDone: hitsDone ?? this.hitsDone,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BuildingEntity &&
      other.id == id &&
      other.blueprint == blueprint &&
      other.position == position &&
      other.hitsDone == hitsDone;

  @override
  int get hashCode => Object.hash(id, blueprint, position, hitsDone);
}
