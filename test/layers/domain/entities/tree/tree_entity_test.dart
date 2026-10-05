import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenTreeIsNewThenFootprintIsItsTrunkAndAllHitsRemain', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final footprint = tree.footprint;

    // then
    expect(footprint, ObstacleEntityMock.treeTrunk);
    expect(tree.hitsRemaining, 5);
    expect(tree.isFelled, isFalse);
  });

  test('testWhenWoodYieldIsNegativeOrHitsToFellIsNotPositiveThenCreationFails', () {
    // given
    final negativeWood = -1;
    final noHits = 0;

    // when
    Object withNegativeWood() => TreeEntityMock.make(woodYield: negativeWood);
    Object withoutHits() => TreeEntityMock.make(hitsToFell: noHits);

    // then
    expect(withNegativeWood, throwsA(isA<AssertionError>()));
    expect(withoutHits, throwsA(isA<AssertionError>()));
  });

  test('testWhenCopyingWithIdAndPositionThenTheRestIsKept', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final copy = tree.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100));

    // then
    expect(copy, TreeEntityMock.neighbour);
    expect(copy.copyWith(id: 'tree-1', position: tree.position), tree);
  });
}
