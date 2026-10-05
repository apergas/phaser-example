import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';

abstract final class BlueprintEntityMock {
  static const BlueprintEntity mock = BlueprintEntity(
    id: BlueprintId.house,
    woodCost: 15,
    hitsToBuild: 8,
    footprintRadius: 40,
  );

  static BlueprintEntity make({int woodCost = 15, int hitsToBuild = 8, double footprintRadius = 40}) {
    return BlueprintEntity(
      id: BlueprintId.house,
      woodCost: woodCost,
      hitsToBuild: hitsToBuild,
      footprintRadius: footprintRadius,
    );
  }
}
