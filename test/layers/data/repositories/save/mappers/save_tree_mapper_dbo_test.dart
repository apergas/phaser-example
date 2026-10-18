import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_tree_mapper_dbo.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../../../mocks/data/datasources/save/save_tree_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  late SaveTreeMapperDBO sut;

  setUp(() {
    sut = SaveTreeMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingATreeToDboThenItKeepsOnlyWhatChanges', () {
    // given
    final tree = TreeEntityMock.oakOfEight.copyWith(hitsTaken: 3);

    // when
    final dbo = sut.toDBO(tree);

    // then
    expect(dbo, SaveTreeDBOMock.withThreeHitsTaken);
  });

  test('testWhenMappingADboToATreeThenTheStatsComeFromTheKind', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;

    // when
    final tree = sut.toEntity(dbo);

    // then
    expect(tree, TreeEntityMock.oakOfEight.copyWith(hitsTaken: 3));
    expect(tree.trunkRadius, Rules.treeTrunkRadius);
    expect(tree.woodYield, Rules.treeKindStats[TreeKind.oak]!.woodYield);
    expect(tree.hitsToFell, Rules.treeKindStats[TreeKind.oak]!.hitsToFell);
  });

  test('testWhenTheTreeHasNoHitsThenItStartsWithZero', () {
    // given
    const dbo = SaveTreeDBOMock.withoutHits;

    // when
    final tree = sut.toEntity(dbo);

    // then
    expect(tree.hitsTaken, 0);
  });

  test('testWhenTheHitsAreOneBelowTheTotalThenTheTreeLoads', () {
    // given
    const dbo = SaveTreeDBOMock.withAlmostAllHits;

    // when
    final tree = sut.toEntity(dbo);

    // then
    expect(tree.hitsTaken, 6);
  });

  test('testWhenTheHitsReachTheTotalThenItThrows', () {
    // given
    const dbo = SaveTreeDBOMock.withAllHits;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('tree tree-1: 7 hits taken of 7'));
  });

  test('testWhenTheHitsAreNegativeThenItThrows', () {
    // given
    const dbo = SaveTreeDBOMock.withNegativeHits;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('tree tree-1: -1 hits taken of 7'));
  });

  test('testWhenTheTreeHasNoIdThenItThrows', () {
    // given
    const dbo = SaveTreeDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('tree without id'));
  });

  test('testWhenTheKindIsUnknownThenItThrows', () {
    // given
    const dbos = [SaveTreeDBOMock.unknownKind, SaveTreeDBOMock.withoutKind];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('tree tree-1: unknown kind "palm"'));
    expect(attempts[1], throwsInvalidSave('tree tree-1: unknown kind "null"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveTreeDBOMock.withoutX, SaveTreeDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('tree tree-1 without x'));
    expect(attempts[1], throwsInvalidSave('tree tree-1 without y'));
  });
}
