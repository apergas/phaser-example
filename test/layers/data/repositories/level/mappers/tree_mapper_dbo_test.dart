import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/core/error-handling/exceptions/app_exceptions.dart';
import 'package:farming/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/rules.dart';

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
    expect(tree.kind, TreeKind.pine);
    expect(tree.position, const PositionEntity(x: 1, y: 2));
  });

  test('testWhenMappingATreeThenTheWoodAndHitsComeFromItsKindAndNotFromTheLevel', () {
    // given
    const dbos = [TreeDBOMock.firstGenerated, TreeDBOMock.secondGenerated, TreeDBOMock.thirdGenerated];

    // when
    final trees = [for (final (index, dbo) in dbos.indexed) sut.toEntity(dbo, index: index)];

    // then
    expect(trees.map((tree) => (tree.woodYield, tree.hitsToFell)), [(6, 5), (9, 8), (4, 3)]);
    expect(trees.map((tree) => tree.trunkRadius).toSet(), {Rules.treeTrunkRadius});
    expect(trees.map((tree) => tree.hitsTaken).toSet(), {0});
  });

  test('testWhenTheKindIsUnknownThenItThrows', () {
    // given
    const dbo = TreeDBOMock.unknownKind;

    // when
    void map() => sut.toEntity(dbo, index: 0);

    // then
    expect(map, throwsA(isA<UnknownTreeKindException>()));
  });
}
