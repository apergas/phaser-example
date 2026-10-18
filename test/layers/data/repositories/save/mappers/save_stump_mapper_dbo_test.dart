import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stump_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_stump_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/tree/stump_entity_mock.dart';

void main() {
  late SaveStumpMapperDBO sut;

  setUp(() {
    sut = SaveStumpMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingAStumpToDboThenItKeepsTheElapsedTime', () {
    // given
    const stump = StumpEntityMock.almostSapling;

    // when
    final dbo = sut.toDBO(stump);

    // then
    expect(dbo, SaveStumpDBOMock.almostSapling);
  });

  test('testWhenMappingADboToAStumpThenEveryFieldComesBack', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;

    // when
    final stump = sut.toEntity(dbo);

    // then
    expect(stump, StumpEntityMock.almostSapling);
  });

  test('testWhenTheStumpHasNoElapsedTimeThenItStartsFresh', () {
    // given
    const dbo = SaveStumpDBOMock.fresh;

    // when
    final stump = sut.toEntity(dbo);

    // then
    expect(stump, StumpEntityMock.fresh);
  });

  test('testWhenTheElapsedTimeIsNegativeThenItThrows', () {
    // given
    const dbo = SaveStumpDBOMock.withNegativeElapsed;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stump tree-1: elapsed ${-1.0} ms'));
  });

  test('testWhenTheStumpHasNoIdThenItThrows', () {
    // given
    const dbo = SaveStumpDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stump without id'));
  });

  test('testWhenTheKindIsUnknownThenItThrows', () {
    // given
    const dbo = SaveStumpDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stump tree-1: unknown kind "palm"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveStumpDBOMock.withoutX, SaveStumpDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('stump tree-1 without x'));
    expect(attempts[1], throwsInvalidSave('stump tree-1 without y'));
  });
}
