import '../../../core/config/constants/enum/blueprint_id.dart';
import '../entities/building/blueprint_entity.dart';

abstract final class Blueprints {
  static const BlueprintEntity house = BlueprintEntity(
    id: BlueprintId.house,
    woodCost: 15,
    hitsToBuild: 8,
    footprintRadius: 40,
  );

  static const List<BlueprintEntity> all = [house];

  static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
}
