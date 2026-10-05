import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../../mocks/data/datasources/level/item_dbo_mock.dart';

void main() {
  late GroundItemMapperDBO sut;

  setUp(() {
    sut = GroundItemMapperDBO();
  });

  test('testWhenItemKindHasDifferentCaseThenMatchesItIgnoringCase', () {
    // given
    const dbo = ItemDBOMock.upperCaseAxe;

    // when
    final item = sut.toEntity(dbo);

    // then
    expect(item.id, 'axe-2');
    expect(item.kind, ToolKind.axe);
    expect(item.position, const PositionEntity(x: 1, y: 2));
  });

  test('testWhenItemHasNoIdThenUsesAnEmptyIdAndDefaultsPositionToZero', () {
    // given
    const dbo = ItemDBOMock.withoutId;

    // when
    final item = sut.toEntity(dbo);

    // then
    expect(item.id, '');
    expect(item.position, const PositionEntity(x: 0, y: 0));
  });

  test('testWhenItemKindIsUnknownThenThrowsUnknownItemKindException', () {
    // given
    const dbo = ItemDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(isA<UnknownItemKindException>().having((exception) => exception.data, 'data', 'mystery: "laser"')),
    );
  });
}
