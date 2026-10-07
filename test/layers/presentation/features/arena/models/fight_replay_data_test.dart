import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';

import '../../../../../mocks/presentation/features/arena/fight_replay_data_mock.dart';

void main() {
  test('testWhenTheReplayStartsThenNothingHasLandedAndEveryoneHasFullHealth', () {
    // given
    // when
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // then
    expect((replay.turnIndex, replay.swingingTurn, replay.isFinished), (-1, null, false));
    expect(replay.durationMs, 400 + 9 * 600);
    expect(replay.healthOf(FightSide.hero, 0), 30);
    expect(replay.healthOf(FightSide.enemy, 0), 20);
  });

  test('testWhenTheFirstSwingIsHalfwayThenTheFirstBlowLands', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final halfway = replay.advanced(699);
    final landed = replay.advanced(700);

    // then
    expect((halfway.turnIndex, halfway.swingingTurn), (-1, 0));
    expect(halfway.healthOf(FightSide.enemy, 0), 20);
    expect((landed.turnIndex, landed.swingingTurn, landed.swingProgress), (0, 0, 0.5));
    expect(landed.healthOf(FightSide.enemy, 0), 16);
  });

  test('testWhenAdvancedPastTheEndThenStopsThereWithEveryTurnPlayed', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final ended = replay.advanced(100000);

    // then
    expect((ended.elapsedMs, ended.turnIndex, ended.swingingTurn, ended.isFinished), (5800, 8, null, true));
    expect(ended.healthOf(FightSide.hero, 0), 22);
    expect(ended.healthOf(FightSide.enemy, 0), 0);
  });

  test('testWhenSkippedThenItIsTheSameAsAdvancingToTheEnd', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final skipped = replay.skipped();

    // then
    expect(skipped, replay.advanced(replay.durationMs));
  });

  test('testWhenASecondWindIsReplayedThenTheHealthBeforeItIsTheLastBlowTaken', () {
    // given
    final replay = FightReplayDataMock.allActionsStart();

    // when
    final afterHeal = replay.advanced(400 + 4 * 600 + 300);

    // then
    expect(afterHeal.turnIndex, 4);
    expect(afterHeal.healthBefore(4, FightSide.hero, 0), 8);
    expect(afterHeal.healthOf(FightSide.hero, 0), 20);
  });
}
