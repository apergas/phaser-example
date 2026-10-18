import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_ground_item_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_item_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/item/ground_item_entity_mock.dart';

void main() {
  late SaveGroundItemMapperDBO sut;

  setUp(() {
    sut = SaveGroundItemMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingAnItemToDboThenItKeepsItsKindByName', () {
    // given
    const item = GroundItemEntityMock.mock;

    // when
    final dbo = sut.toDBO(item);

    // then
    expect(dbo, SaveItemDBOMock.axe);
  });

  test('testWhenMappingADboToAnItemThenEveryFieldComesBack', () {
    // given
    const dbo = SaveItemDBOMock.axe;

    // when
    final item = sut.toEntity(dbo);

    // then
    expect(item, GroundItemEntityMock.mock);
  });

  test('testWhenTheItemHasNoIdThenItThrows', () {
    // given
    const dbo = SaveItemDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('item without id'));
  });

  test('testWhenTheKindIsUnknownThenItThrows', () {
    // given
    const dbo = SaveItemDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('item axe-1: unknown kind "hammer"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveItemDBOMock.withoutX, SaveItemDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('item axe-1 without x'));
    expect(attempts[1], throwsInvalidSave('item axe-1 without y'));
  });
}
