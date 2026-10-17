import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/building/building_entity.dart';
import '../../entities/geometry/position_entity.dart';
import '../../rules/rules.dart';
import 'position_geometry.dart';

extension BuildingRules on BuildingEntity {
  bool get acceptsDeposits => isComplete && blueprint.accepts.isNotEmpty;

  bool boostsMining(PositionEntity rockPosition) =>
      isComplete && blueprint.id == BlueprintId.quarry && position.distanceTo(rockPosition) < Rules.quarryBoostRange;

  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}

extension BuildingListRules on Iterable<BuildingEntity> {
  bool hasComplete(BlueprintId id) => any((building) => building.blueprint.id == id && building.isComplete);

  int completeCount(BlueprintId id) => where((building) => building.blueprint.id == id && building.isComplete).length;
}
