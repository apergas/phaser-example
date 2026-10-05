import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';

import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenTreeIsNewThenFootprintIsItsTrunkAndAllHitsRemain', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final footprint = tree.footprint;

    // then
    expect(footprint, const ObstacleEntity(position: PositionEntity(x: 200, y: 100), radius: 10));
    expect(tree.hitsRemaining, 5);
    expect(tree.isFelled, isFalse);
  });

  test('testWhenWoodYieldIsNegativeOrHitsToFellIsNotPositiveThenCreationFails', () {
    // given
    final negativeWood = -1;
    final noHits = 0;

    // when / then
    expect(
      () => TreeEntity(
        id: 'tree-1',
        kind: TreeKind.oak,
        position: const PositionEntity(x: 0, y: 0),
        trunkRadius: 10,
        woodYield: negativeWood,
        hitsToFell: 5,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => TreeEntity(
        id: 'tree-1',
        kind: TreeKind.oak,
        position: const PositionEntity(x: 0, y: 0),
        trunkRadius: 10,
        woodYield: 6,
        hitsToFell: noHits,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('testWhenCopyingWithIdAndPositionThenTheRestIsKept', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final copy = tree.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100));

    // then
    expect(copy.id, 'neighbour');
    expect(copy.position, const PositionEntity(x: 165, y: 100));
    expect(copy.copyWith(id: 'tree-1', position: tree.position), tree);
  });
}
