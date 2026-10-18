import 'package:farming/layers/domain/entities/building/blueprint_entity.dart';
import 'package:farming/layers/domain/entities/building/building_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

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

  static BuildingEntity completed(BlueprintEntity blueprint, {String id = 'building-1', PositionEntity? position}) =>
      BuildingEntity(
        id: id,
        blueprint: blueprint,
        position: position ?? const PositionEntity(x: 600, y: 600),
        hitsDone: blueprint.hitsToBuild,
      );

  static BuildingEntity site(BlueprintEntity blueprint, {String id = 'building-1', PositionEntity? position}) =>
      BuildingEntity(id: id, blueprint: blueprint, position: position ?? const PositionEntity(x: 600, y: 600));
}
