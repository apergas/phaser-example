import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_decoration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_decoration_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/decoration/decoration_entity_mock.dart';

void main() {
  late SaveDecorationMapperDBO sut;

  setUp(() {
    sut = SaveDecorationMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingADecorationToDboThenItKeepsItsKindByName', () {
    // given
    const decoration = DecorationEntityMock.mock;

    // when
    final dbo = sut.toDBO(decoration);

    // then
    expect(dbo, SaveDecorationDBOMock.rock);
  });

  test('testWhenMappingADboToADecorationThenEveryFieldComesBack', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;

    // when
    final decoration = sut.toEntity(dbo);

    // then
    expect(decoration, DecorationEntityMock.mock);
  });

  test('testWhenTheDecorationHasNoIdThenItThrows', () {
    // given
    const dbo = SaveDecorationDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('decoration without id'));
  });

  test('testWhenTheKindIsUnknownThenItThrows', () {
    // given
    const dbo = SaveDecorationDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('decoration decoration-1: unknown kind "flower"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveDecorationDBOMock.withoutX, SaveDecorationDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('decoration decoration-1 without x'));
    expect(attempts[1], throwsInvalidSave('decoration decoration-1 without y'));
  });
}
