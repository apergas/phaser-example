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

  static const List<BlueprintEntity> all = [house];

  static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
}
