import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/construction_rejection.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';

void main() {
  test('testWhenComparingResultsThenBuildingAndReasonMatter', () {
    // given
    const started = ConstructionStartedEntity(building: BuildingEntityMock.mock);
    const rejected = ConstructionRejectedEntity(reason: ConstructionRejection.blocked);

    // when
    final sameStarted = started == const ConstructionStartedEntity(building: BuildingEntityMock.mock);
    final sameRejected = rejected == const ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
    final otherReason = rejected == const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood);

    // then
    expect(sameStarted, isTrue);
    expect(sameRejected, isTrue);
    expect(otherReason, isFalse);
  });
}
