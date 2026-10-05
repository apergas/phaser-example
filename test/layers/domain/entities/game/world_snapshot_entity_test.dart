import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../../mocks/domain/entities/game/world_snapshot_entity_mock.dart';
import '../../../../mocks/domain/entities/item/ground_item_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenListsHaveTheSameContentThenSnapshotsAreEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final copy = WorldSnapshotEntity(
      width: 1000,
      height: 1000,
      trees: [TreeEntityMock.mock],
      items: [GroundItemEntityMock.mock],
      decorations: [],
      buildings: [BuildingEntityMock.mock],
    );

    // then
    expect(copy, snapshot);
    expect(copy.hashCode, snapshot.hashCode);
  });

  test('testWhenATreeIsMissingThenSnapshotsAreNotEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final withoutTrees = WorldSnapshotEntity(
      width: 1000,
      height: 1000,
      trees: [],
      items: [GroundItemEntityMock.mock],
      decorations: [],
      buildings: [BuildingEntityMock.mock],
    );

    // then
    expect(withoutTrees == snapshot, isFalse);
  });
}
