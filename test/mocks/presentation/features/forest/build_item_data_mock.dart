import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';

abstract final class BuildItemDataMock {
  static final BuildItemData affordable = BuildItemData(
    blueprint: BlueprintId.house,
    name: 'Casa',
    costText: '15 de madera',
    missingText: null,
    isEnabled: true,
  );

  static final BuildItemData unaffordable = BuildItemData(
    blueprint: BlueprintId.house,
    name: 'Casa',
    costText: '15 de madera',
    missingText: 'Faltan 9',
    isEnabled: false,
  );
}
