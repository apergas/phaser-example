import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/level/tree_dbo_mock.dart';

void main() {
  late TreeMapperDBO sut;

  setUp(() {
    sut = TreeMapperDBO();
  });

  test('testWhenTreeHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = TreeDBOMock.withoutId;

    // when
    final tree = sut.toEntity(dbo, index: 4);

    // then
    expect(tree.id, 'tree-5');
    expect(tree.woodYield, 0);
    expect(tree.kind, TreeKind.pine);
  });
}
