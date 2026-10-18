import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/placement_rule_entity.dart';
import 'rules.dart';

abstract final class Blueprints {
  static const BlueprintEntity house = BlueprintEntity(
    id: BlueprintId.house,
    cost: {Resource.wood: 15},
    hitsToBuild: 8,
    footprintRadius: 40,
  );

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
    placementRule: NearRockPlacementRuleEntity(range: Rules.quarryRockRange),
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

  static const List<BlueprintEntity> all = [house, storehouse, quarry, workshop, forge, armory, mageTower, camp];

  static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
}
