import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';

abstract final class BuildOptionEntityMock {
  static const BuildOptionEntity mock = BuildOptionEntity(
    blueprint: BlueprintId.house,
    woodCost: 15,
    isAffordable: true,
  );

  static BuildOptionEntity make({bool isAffordable = true}) =>
      BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: isAffordable);
}
