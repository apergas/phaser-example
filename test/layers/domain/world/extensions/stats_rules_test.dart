import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/world/extensions/stats_rules.dart';

import '../../../../mocks/domain/entities/game/stats_entity_mock.dart';

void main() {
  test('testWhenNoTreeOfAKindWasFelledThenItsCountIsZero', () {
    // given
    const stats = StatsEntityMock.afterOnePine;

    // when
    final oaks = stats.treesFelledOf(TreeKind.oak);

    // then
    expect((oaks, stats.treesFelledOf(TreeKind.pine)), (0, 1));
  });

  test('testWhenFellingATreeOfAKindThenBothCountersGrow', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    final felled = stats.fellingTree(TreeKind.oak);

    // then
    expect(felled, StatsEntityMock.afterOneOak);
  });

  test('testWhenFellingATreeWithoutAKindThenOnlyTheTotalGrows', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    final felled = stats.fellingTree(null);

    // then
    expect(felled, StatsEntityMock.afterOneUnknownTree);
  });

  test('testWhenCompletingABuildingOrRegrowingATreeThenOnlyThatCounterGrows', () {
    // given
    const stats = StatsEntityMock.empty;

    // when
    final completed = stats.completingBuilding();
    final regrown = stats.regrowingTree();

    // then
    expect(completed, StatsEntityMock.afterOneHouse);
    expect(regrown, StatsEntityMock.afterOneRegrowth);
  });
}
