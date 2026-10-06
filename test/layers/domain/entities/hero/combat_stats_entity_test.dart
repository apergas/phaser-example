import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';

void main() {
  test('testWhenComputingPowerThenItWeighsAttackDefenseAndHalfTheHealth', () {
    // given
    const stats = CombatStatsEntityMock.heroBase;

    // when
    final power = stats.power;

    // then
    expect(power, 31);
  });

  test('testWhenCopyingWithAttackThenDefenseAndHealthAreKept', () {
    // given
    const stats = CombatStatsEntityMock.heroBase;

    // when
    final copy = stats.copyWith(attack: 7, defense: 3, health: 40);

    // then
    expect(copy, CombatStatsEntityMock.heroWithShortSwordAndLeather);
    expect(copy.hashCode, CombatStatsEntityMock.heroWithShortSwordAndLeather.hashCode);
  });
}
