import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/building/building_entity.dart';

extension BuildingRules on BuildingEntity {
  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}

extension BuildingListRules on Iterable<BuildingEntity> {
  bool hasComplete(BlueprintId id) => any((building) => building.blueprint.id == id && building.isComplete);
}
