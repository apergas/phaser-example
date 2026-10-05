import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/level/decoration_dbo_mock.dart';

void main() {
  late DecorationMapperDBO sut;

  setUp(() {
    sut = DecorationMapperDBO();
  });

  test('testWhenDecorationHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = DecorationDBOMock.withoutId;

    // when
    final decoration = sut.toEntity(dbo, index: 0);

    // then
    expect(decoration.id, 'decoration-1');
    expect(decoration.kind, DecorationKind.mushrooms);
  });
}
