import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/tree/tree_stats_entity.dart';

import '../../../../mocks/domain/entities/tree/tree_stats_entity_mock.dart';

void main() {
  test('testWhenCopyingWithWoodAndHitsThenTheCopyEqualsTheOtherStats', () {
    // given
    const stats = TreeStatsEntityMock.pine;

    // when
    final copy = stats.copyWith(woodYield: 8, hitsToFell: 7);

    // then
    expect(copy, TreeStatsEntityMock.oak);
    expect(copy.hashCode, TreeStatsEntityMock.oak.hashCode);
    expect(stats.copyWith(), stats);
  });

  test('testWhenWoodOrHitsDifferThenStatsAreNotEqual', () {
    // given
    const stats = TreeStatsEntityMock.oak;

    // when
    final otherWood = stats == stats.copyWith(woodYield: 9);
    final otherHits = stats == stats.copyWith(hitsToFell: 8);

    // then
    expect((otherWood, otherHits), (false, false));
  });

  test('testWhenTheWoodIsNegativeOrTheHitsAreZeroThenItAsserts', () {
    // given
    const stats = TreeStatsEntityMock.pine;

    // when
    TreeStatsEntity negativeWood() => stats.copyWith(woodYield: -1);
    TreeStatsEntity zeroHits() => stats.copyWith(hitsToFell: 0);

    // then
    expect(negativeWood, throwsA(isA<AssertionError>()));
    expect(zeroHits, throwsA(isA<AssertionError>()));
  });
}
