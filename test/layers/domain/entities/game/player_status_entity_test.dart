import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/player_status_entity_mock.dart';

void main() {
  test('testWhenTargetsDifferThenStatusesAreNotEqual', () {
    // given
    const status = PlayerStatusEntityMock.mock;

    // when
    final sameStatus = status == PlayerStatusEntityMock.make();
    final withTarget = status == PlayerStatusEntityMock.withTarget;

    // then
    expect(sameStatus, isTrue);
    expect(withTarget, isFalse);
  });
}
