import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/world/extensions/stump_rules.dart';

import '../../../../mocks/domain/entities/tree/stump_entity_mock.dart';

void main() {
  test('testWhenTheStumpIsOneMillisecondShortThenItIsNotASaplingYet', () {
    // given
    const stump = StumpEntityMock.almostSapling;

    // when
    final isSapling = stump.isSapling;

    // then
    expect(isSapling, isFalse);
  });

  test('testWhenTheStumpReachesSixtySecondsThenItIsASapling', () {
    // given
    const stump = StumpEntityMock.sapling;

    // when
    final state = (stump.isSapling, stump.isReadyToRegrow);

    // then
    expect(state, (true, false));
  });

  test('testWhenTheStumpReachesThreeMinutesThenItIsReadyToRegrow', () {
    // given
    const stump = StumpEntityMock.ready;

    // when
    final state = (stump.isSapling, stump.isReadyToRegrow);

    // then
    expect(state, (true, true));
  });

  test('testWhenGrowingThenTheTimeAddsUp', () {
    // given
    const stump = StumpEntityMock.almostSapling;

    // when
    final grown = stump.grown(1);

    // then
    expect(grown, StumpEntityMock.sapling);
  });

  test('testWhenGrowingPastThreeMinutesThenTheTimeStopsAtThreeMinutes', () {
    // given
    const stump = StumpEntityMock.ready;

    // when
    final grown = stump.grown(5000);

    // then
    expect(grown.elapsedMs, 180000);
    expect(StumpEntityMock.almostReady.grown(100), StumpEntityMock.ready);
  });
}
