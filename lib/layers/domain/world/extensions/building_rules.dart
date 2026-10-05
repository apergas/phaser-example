import '../../entities/building/building_entity.dart';

extension BuildingRules on BuildingEntity {
  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}
