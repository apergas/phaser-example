import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';

abstract final class BuildItemDataMock {
  static BuildItemData get affordable => BuildItemData(
    blueprint: BlueprintId.house,
    name: Internationalize.forestBlueprint(id: BlueprintId.house),
    costText: Internationalize.forestCost(wood: 15),
    missingText: null,
    isEnabled: true,
  );

  static BuildItemData get unaffordable => makeUnaffordable(missingWood: 9);

  static BuildItemData makeUnaffordable({required int missingWood}) => BuildItemData(
    blueprint: BlueprintId.house,
    name: Internationalize.forestBlueprint(id: BlueprintId.house),
    costText: Internationalize.forestCost(wood: 15),
    missingText: Internationalize.forestMissing(wood: missingWood),
    isEnabled: false,
  );
}
