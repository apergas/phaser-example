import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';

abstract final class BuildOptionEntityMock {
  static const BuildOptionEntity mock = BuildOptionEntity(
    blueprint: BlueprintId.house,
    cost: {Resource.wood: 15},
    missing: {},
  );

  static const BuildOptionEntity unaffordable = BuildOptionEntity(
    blueprint: BlueprintId.house,
    cost: {Resource.wood: 15},
    missing: {Resource.wood: 5},
  );

  static BuildOptionEntity make({Map<Resource, int> missing = const {}}) =>
      BuildOptionEntity(blueprint: BlueprintId.house, cost: const {Resource.wood: 15}, missing: missing);
}
