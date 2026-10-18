import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/tree/tree_stats_entity_mock.dart';

void main() {
  test('testWhenReadingTheTreeKindStatsThenEveryKindHasItsWoodAndHits', () {
    // given
    const kinds = TreeKind.values;

    // when
    final missing = kinds.where((kind) => !Rules.treeKindStats.containsKey(kind));

    // then
    expect(missing, isEmpty);
    expect(Rules.treeKindStats, hasLength(kinds.length));
  });

  test('testWhenReadingTheTreeKindStatsThenPinesAreQuickAndOldTreesAreWorthTheMost', () {
    // given
    const stats = Rules.treeKindStats;

    // when
    final picked = [stats[TreeKind.pine], stats[TreeKind.oak], stats[TreeKind.old], stats[TreeKind.round]];

    // then
    expect(picked, [
      TreeStatsEntityMock.pine,
      TreeStatsEntityMock.oak,
      TreeStatsEntityMock.old,
      TreeStatsEntityMock.round,
    ]);
    expect(stats.values.map((stat) => stat.woodYield).reduce((a, b) => a > b ? a : b), 9);
    expect(stats.values.map((stat) => stat.hitsToFell).reduce((a, b) => a < b ? a : b), 3);
  });

  test('testWhenReadingTheRockRulesThenARockTakesSevenHitsAndGivesEightStone', () {
    // given
    const rules = (Rules.rockHitsToBreak, Rules.rockStoneYield);

    // when
    final (hits, stone) = rules;

    // then
    expect((hits, stone), (7, 8));
  });
}
