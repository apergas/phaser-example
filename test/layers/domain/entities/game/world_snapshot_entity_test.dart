import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/world_snapshot_entity_mock.dart';

void main() {
  test('testWhenListsHaveTheSameContentThenSnapshotsAreEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final copy = WorldSnapshotEntityMock.make();

    // then
    expect(copy, snapshot);
    expect(copy.hashCode, snapshot.hashCode);
  });

  test('testWhenATreeIsMissingThenSnapshotsAreNotEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final isEqual = WorldSnapshotEntityMock.withoutTrees == snapshot;

    // then
    expect(isEqual, isFalse);
  });
}
