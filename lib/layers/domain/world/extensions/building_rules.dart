import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/building/building_entity.dart';

extension BuildingRules on BuildingEntity {
  bool get acceptsDeposits => isComplete && blueprint.isDropOff;

  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}

extension BuildingListRules on Iterable<BuildingEntity> {
  bool hasComplete(BlueprintId id) => any((building) => building.blueprint.id == id && building.isComplete);

  int completeCount(BlueprintId id) => where((building) => building.blueprint.id == id && building.isComplete).length;
}
