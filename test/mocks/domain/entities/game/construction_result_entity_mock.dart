import 'package:rpg/core/config/constants/enum/construction_rejection.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';

import '../building/building_entity_mock.dart';

abstract final class ConstructionResultEntityMock {
  static const ConstructionStartedEntity started = ConstructionStartedEntity(building: BuildingEntityMock.mock);

  static const ConstructionRejectedEntity blocked = ConstructionRejectedEntity(reason: ConstructionRejection.blocked);

  static const ConstructionRejectedEntity notEnoughResources = ConstructionRejectedEntity(
    reason: ConstructionRejection.notEnoughResources,
  );

  static ConstructionStartedEntity makeStarted() =>
      ConstructionStartedEntity(building: BuildingEntityMock.mock.copyWith());

  static ConstructionRejectedEntity makeBlocked() => ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
}
