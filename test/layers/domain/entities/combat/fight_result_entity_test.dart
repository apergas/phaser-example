import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';

import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';

void main() {
  test('testWhenTwoPlayedFightsHaveTheSameLogAndAdviceThenTheyAreEqual', () {
    // given
    final result = FightResultEntityMock.almostBeatDuelist();

    // when
    final other = FightResultEntityMock.almostBeatDuelist();

    // then
    expect(other, result);
    expect(other.hashCode, result.hashCode);
  });

  test('testWhenTheLogsDifferThenThePlayedFightsAreNotEqual', () {
    // given
    final result = FightResultEntityMock.victoryOverBandit();

    // when
    final equal = result == FightResultEntityMock.almostBeatDuelist();

    // then
    expect(equal, isFalse);
  });

  test('testWhenOnlyOneFightCrownsAChampionThenTheyAreNotEqual', () {
    // given
    final result = FightResultEntityMock.victoryOverBandit();

    // when
    final equal = result == FightResultEntityMock.championshipOverBandit();

    // then
    expect(equal, isFalse);
  });

  test('testWhenComparingALockedFightWithAPlayedOneThenTheyAreNotEqual', () {
    // given
    const FightResultEntity locked = FightResultEntityMock.locked;

    // when
    final equal = locked == FightResultEntityMock.victoryOverBandit();

    // then
    expect(equal, isFalse);
    expect(locked, FightResultEntityMock.locked);
  });
}
