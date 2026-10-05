import 'package:rpg/layers/domain/entities/building/building_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

abstract final class BuildingEntityMock {
  static const BuildingEntity mock = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 0, y: 0),
  );

  static const BuildingEntity halfBuilt = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 0, y: 0),
    hitsDone: 4,
  );

  static const BuildingEntity complete = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 0, y: 0),
    hitsDone: 8,
  );

  static const BuildingEntity farCorner = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 500, y: 500),
  );
}
