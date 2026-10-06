import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';

void main() {
  test('testWhenTheHeroWinsThenTheLogIsAVictoryWithItsLastRound', () {
    // given
    final log = FightLogEntityMock.victoryOverBandit();

    // when
    final summary = (log.isVictory, log.rounds);

    // then
    expect(summary, (true, 5));
  });

  test('testWhenTheHeroLosesThenTheLogIsNotAVictory', () {
    // given
    final log = FightLogEntityMock.defeatByBrute();

    // when
    final summary = (log.isVictory, log.rounds);

    // then
    expect(summary, (false, 1));
  });

  test('testWhenTwoLogsHaveTheSameTurnsThenTheyAreEqual', () {
    // given
    final log = FightLogEntityMock.victoryOverBandit();

    // when
    final other = FightLogEntityMock.victoryOverBandit();

    // then
    expect(other, log);
    expect(other.hashCode, log.hashCode);
  });
}
