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

  test('testWhenTheChanceIsNotGivenThenEnemiesNeverUseSkills', () {
    // given
    const level = ArenaLevelEntityMock.banditRookie;

    // when
    final chance = level.enemySkillChance;

    // then
    expect(chance, 0);
  });

  test('testWhenCopyingWithAChanceThenOnlyTheChanceChanges', () {
    // given
    const level = ArenaLevelEntityMock.banditTrio;

    // when
    final copy = level.copyWith(enemySkillChance: 0.02);

    // then
    expect(copy, ArenaLevelEntityMock.banditTrioWithEnemySkills);
    expect(copy.hashCode, ArenaLevelEntityMock.banditTrioWithEnemySkills.hashCode);
    expect(level.copyWith(), level);
  });

  test('testWhenTheChanceDiffersThenLevelsAreNotEqual', () {
    // given
    const level = ArenaLevelEntityMock.banditTrio;

    // when
    final equal = level == ArenaLevelEntityMock.banditTrioWithEnemySkills;

    // then
    expect(equal, isFalse);
  });

  test('testWhenTheChanceIsOutOfRangeThenItAsserts', () {
    // given
    const level = ArenaLevelEntityMock.banditTrio;

    // when
    void negative() => level.copyWith(enemySkillChance: -0.1);
    void aboveOne() => level.copyWith(enemySkillChance: 1.5);

    // then
    expect(negative, throwsA(isA<AssertionError>()));
    expect(aboveOne, throwsA(isA<AssertionError>()));
  });
}
