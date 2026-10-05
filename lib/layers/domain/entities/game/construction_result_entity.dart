import '../../../../core/config/constants/enum/construction_rejection.dart';
import '../building/building_entity.dart';

sealed class ConstructionResultEntity {
  const ConstructionResultEntity();
}

final class ConstructionStartedEntity extends ConstructionResultEntity {
  final BuildingEntity building;

  const ConstructionStartedEntity({required this.building});

  @override
  bool operator ==(Object other) => other is ConstructionStartedEntity && other.building == building;

  @override
  int get hashCode => Object.hash(ConstructionStartedEntity, building);
}

final class ConstructionRejectedEntity extends ConstructionResultEntity {
  final ConstructionRejection reason;

  const ConstructionRejectedEntity({required this.reason});

  @override
  bool operator ==(Object other) => other is ConstructionRejectedEntity && other.reason == reason;

  @override
  int get hashCode => Object.hash(ConstructionRejectedEntity, reason);
}
