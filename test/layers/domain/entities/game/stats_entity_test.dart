import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/game/stats_entity.dart';

import '../../../../mocks/domain/entities/game/stats_entity_mock.dart';

void main() {
  test('testWhenCreatedThenEveryCounterIsZero', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    final counters = (stats.treesFelled, stats.treesFelledByKind.length, stats.buildingsCompleted, stats.treesRegrown);

    // then
    expect(counters, (0, 0, 0, 0));
  });

  test('testWhenCopyingWithCountersThenTheCopyEqualsTheSameStats', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    final copy = stats.copyWith(treesFelled: 1, treesFelledByKind: {TreeKind.pine: 1});

    // then
    expect(copy, StatsEntityMock.afterOnePine);
    expect(copy.hashCode, StatsEntityMock.afterOnePine.hashCode);
    expect(stats.copyWith(), stats);
  });

  test('testWhenTheTreesByKindDifferThenStatsAreNotEqual', () {
    // given
    const stats = StatsEntityMock.afterOnePine;

    // when
    final equal = stats == StatsEntityMock.afterOneOak;

    // then
    expect(equal, isFalse);
  });

  test('testWhenACounterIsNegativeThenItAsserts', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    StatsEntity felled() => stats.copyWith(treesFelled: -1);
    StatsEntity completed() => stats.copyWith(buildingsCompleted: -1);
    StatsEntity regrown() => stats.copyWith(treesRegrown: -1);

    // then
    expect(felled, throwsA(isA<AssertionError>()));
    expect(completed, throwsA(isA<AssertionError>()));
    expect(regrown, throwsA(isA<AssertionError>()));
  });
}
