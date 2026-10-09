import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';

void main() {
  test('testWhenComputingLevelPowerThenItAddsThePowerOfEveryEnemy', () {
    // given
    const level = ArenaLevelEntityMock.banditTrio;

    // when
    final power = level.power;

    // then
    expect(power, 57);
  });
}
