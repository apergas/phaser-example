import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';

abstract final class BlueprintEntityMock {
  static const BlueprintEntity mock = BlueprintEntity(
    id: BlueprintId.house,
    cost: {Resource.wood: 15},
    hitsToBuild: 8,
    footprintRadius: 40,
  );

  static BlueprintEntity make({
    Map<Resource, int> cost = const {Resource.wood: 15},
    int hitsToBuild = 8,
    double footprintRadius = 40,
  }) {
    return BlueprintEntity(
      id: BlueprintId.house,
      cost: cost,
      hitsToBuild: hitsToBuild,
      footprintRadius: footprintRadius,
    );
  }

  static const BlueprintEntity forge = BlueprintEntity(
    id: BlueprintId.forge,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity armory = BlueprintEntity(
    id: BlueprintId.armory,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity mageTower = BlueprintEntity(
    id: BlueprintId.mageTower,
    cost: {Resource.wood: 30, Resource.gold: 40},
    hitsToBuild: 12,
    footprintRadius: 40,
  );
}
