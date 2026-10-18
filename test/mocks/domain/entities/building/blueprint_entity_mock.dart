import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/building/blueprint_entity.dart';
import 'package:farming/layers/domain/entities/building/placement_rule_entity.dart';

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
    bool isBuildable = true,
    PlacementRuleEntity placementRule = const AnywherePlacementRuleEntity(),
  }) {
    return BlueprintEntity(
      id: BlueprintId.house,
      cost: cost,
      hitsToBuild: hitsToBuild,
      footprintRadius: footprintRadius,
      isBuildable: isBuildable,
      placementRule: placementRule,
    );
  }

  static const BlueprintEntity storehouse = BlueprintEntity(
    id: BlueprintId.storehouse,
    cost: {Resource.wood: 20},
    hitsToBuild: 8,
    footprintRadius: 40,
  );

  static const BlueprintEntity quarry = BlueprintEntity(
    id: BlueprintId.quarry,
    cost: {Resource.wood: 25},
    hitsToBuild: 8,
    footprintRadius: 40,
    placementRule: NearRockPlacementRuleEntity(range: 120),
  );

  static const BlueprintEntity workshop = BlueprintEntity(
    id: BlueprintId.workshop,
    cost: {Resource.wood: 20, Resource.stone: 10},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity forge = BlueprintEntity(
    id: BlueprintId.forge,
    cost: {Resource.wood: 25, Resource.stone: 10},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity armory = BlueprintEntity(
    id: BlueprintId.armory,
    cost: {Resource.wood: 25, Resource.stone: 10},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity mageTower = BlueprintEntity(
    id: BlueprintId.mageTower,
    cost: {Resource.wood: 30, Resource.gold: 40, Resource.stone: 10},
    hitsToBuild: 12,
    footprintRadius: 40,
  );

  static const BlueprintEntity camp = BlueprintEntity(
    id: BlueprintId.camp,
    cost: {},
    hitsToBuild: 1,
    footprintRadius: 30,
    isBuildable: false,
  );
}
