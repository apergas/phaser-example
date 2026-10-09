import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/building/blueprint_entity.dart';

abstract final class Blueprints {
  static const BlueprintEntity house = BlueprintEntity(
    id: BlueprintId.house,
    cost: {Resource.wood: 15},
    hitsToBuild: 8,
    footprintRadius: 40,
  );

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

  static const List<BlueprintEntity> all = [house, forge, armory, mageTower];

  static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
}
