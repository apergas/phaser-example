import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stats_mapper_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_stats_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_stats_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SaveStatsMapperDBO sut;

  setUp(() {
    sut = SaveStatsMapperDBO();
  });

  test('testWhenMappingStatsToDboThenTheKindsKeepTheirNames', () {
    // given
    const stats = SaveScenarioMock.stats;

    // when
    final dbo = sut.toDBO(stats);

    // then
    expect(dbo, SaveStatsDBOMock.mock);
  });

  test('testWhenMappingADboToStatsThenEveryCounterComesBack', () {
    // given
    const dbo = SaveStatsDBOMock.mock;

    // when
    final stats = sut.toEntity(dbo);

    // then
    expect(stats, SaveScenarioMock.stats);
    expect(stats.treesFelledByKind, {TreeKind.pine: 3, TreeKind.oak: 1});
  });

  test('testWhenThereIsNoDboOrItHasNoFieldsThenTheStatsAreEmpty', () {
    // given
    const SaveStatsDBO? missing = null;
    const empty = SaveStatsDBOMock.empty;

    // when
    final fromNothing = sut.toEntity(missing);
    final fromEmpty = sut.toEntity(empty);

    // then
    expect(fromNothing, StatsEntityMock.empty);
    expect(fromEmpty, StatsEntityMock.empty);
  });

  test('testWhenATreeKindIsUnknownThenItThrows', () {
    // given
    const dbo = SaveStatsDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stats: unknown tree kind "palm"'));
  });

  test('testWhenACounterIsNegativeThenItThrowsNamingTheField', () {
    // given
    const dbos = [
      SaveStatsDBOMock.negativeTreesFelled,
      SaveStatsDBOMock.negativeKindCount,
      SaveStatsDBOMock.negativeBuildings,
      SaveStatsDBOMock.negativeRegrown,
    ];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('stats: treesFelled -1'));
    expect(attempts[1], throwsInvalidSave('stats: treesFelledByKind.pine -1'));
    expect(attempts[2], throwsInvalidSave('stats: buildingsCompleted -2'));
    expect(attempts[3], throwsInvalidSave('stats: treesRegrown -3'));
  });
}
