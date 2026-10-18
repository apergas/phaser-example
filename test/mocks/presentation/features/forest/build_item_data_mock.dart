import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/presentation/features/forest/models/build_item_data.dart';

import '../../../domain/entities/game/build_option_entity_mock.dart';

abstract final class BuildItemDataMock {
  static BuildItemData get affordable => BuildItemData(
    blueprint: BlueprintId.house,
    name: Internationalize.forestBlueprint(id: BlueprintId.house),
    costText: Internationalize.forestAmount(resource: Resource.wood, amount: 15),
    missingText: null,
    isEnabled: true,
  );

  static BuildItemData get unaffordable => makeUnaffordable(missingWood: 9);

  static BuildItemData makeUnaffordable({required int missingWood}) => BuildItemData(
    blueprint: BlueprintId.house,
    name: Internationalize.forestBlueprint(id: BlueprintId.house),
    costText: Internationalize.forestAmount(resource: Resource.wood, amount: 15),
    missingText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
    ),
    isEnabled: false,
  );

  static BuildItemData workshopUnaffordable(BlueprintId id, {required int missingWood}) => BuildItemData(
    blueprint: id,
    name: Internationalize.forestBlueprint(id: id),
    costText: Internationalize.forestAmount(resource: Resource.wood, amount: 25),
    missingText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
    ),
    isEnabled: false,
  );

  static List<BuildItemData> get everyBlueprintUnaffordable => [
    for (final id in BlueprintId.values) workshopUnaffordable(id, missingWood: 25),
  ];

  static BuildItemData mageTowerUnaffordable({required int missingWood}) => BuildItemData(
    blueprint: BlueprintId.mageTower,
    name: Internationalize.forestBlueprint(id: BlueprintId.mageTower),
    costText: [
      Internationalize.forestAmount(resource: Resource.wood, amount: 30),
      Internationalize.forestAmount(resource: Resource.gold, amount: 40),
    ].join(', '),
    missingText: Internationalize.forestMissing(
      amounts: [
        Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
        Internationalize.forestAmount(resource: Resource.gold, amount: 40),
      ].join(', '),
    ),
    isEnabled: false,
  );

  static List<BuildItemData> everyBuildableWithStock({int wood = 0}) => [
    for (final option in BuildOptionEntityMock.everyBuildableWithStock(wood: wood))
      BuildItemData(
        blueprint: option.blueprint,
        name: Internationalize.forestBlueprint(id: option.blueprint),
        costText: _amounts(option.cost),
        missingText: option.missing.isEmpty ? null : Internationalize.forestMissing(amounts: _amounts(option.missing)),
        isEnabled: option.missing.isEmpty,
      ),
  ];

  static String _amounts(Map<Resource, int> amounts) => [
    for (final resource in Resource.values)
      if (amounts[resource] case final amount?) Internationalize.forestAmount(resource: resource, amount: amount),
  ].join(', ');
}
