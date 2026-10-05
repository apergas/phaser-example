import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/construction_result_entity_mock.dart';

void main() {
  test('testWhenComparingResultsThenBuildingAndReasonMatter', () {
    // given
    const started = ConstructionResultEntityMock.started;
    const rejected = ConstructionResultEntityMock.blocked;

    // when
    final sameStarted = started == ConstructionResultEntityMock.makeStarted();
    final sameRejected = rejected == ConstructionResultEntityMock.makeBlocked();
    final otherReason = rejected == ConstructionResultEntityMock.notEnoughWood;

    // then
    expect(sameStarted, isTrue);
    expect(sameRejected, isTrue);
    expect(otherReason, isFalse);
  });
}
