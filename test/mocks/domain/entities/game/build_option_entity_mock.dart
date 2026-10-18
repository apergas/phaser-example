import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/building/blueprint_entity.dart';
import 'package:farming/layers/domain/entities/game/build_option_entity.dart';

import '../building/blueprint_entity_mock.dart';

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

  static const List<BlueprintEntity> buildable = [
    BlueprintEntityMock.mock,
    BlueprintEntityMock.workshop,
    BlueprintEntityMock.forge,
    BlueprintEntityMock.armory,
    BlueprintEntityMock.mageTower,
  ];

  static List<BuildOptionEntity> everyBuildableWithStock({int wood = 0}) => [
    for (final blueprint in buildable)
      BuildOptionEntity(
        blueprint: blueprint.id,
        cost: blueprint.cost,
        missing: {
          for (final MapEntry(key: resource, value: quantity) in blueprint.cost.entries)
            if (quantity > (resource == Resource.wood ? wood : 0))
              resource: quantity - (resource == Resource.wood ? wood : 0),
        },
      ),
  ];
}
