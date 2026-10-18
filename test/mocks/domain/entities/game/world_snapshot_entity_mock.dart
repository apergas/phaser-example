import 'package:farming/layers/domain/entities/game/world_snapshot_entity.dart';

import '../building/building_entity_mock.dart';
import '../item/ground_item_entity_mock.dart';
import '../rock/rock_entity_mock.dart';
import '../tree/stump_entity_mock.dart';
import '../tree/tree_entity_mock.dart';

abstract final class WorldSnapshotEntityMock {
  static const WorldSnapshotEntity mock = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [TreeEntityMock.mock],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
    stumps: [],
    rocks: [],
  );

  static const WorldSnapshotEntity withoutTrees = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
    stumps: [],
    rocks: [],
  );

  static WorldSnapshotEntity make() {
    return WorldSnapshotEntity(
      width: 1000,
      height: 1000,
      trees: [TreeEntityMock.mock],
      items: [GroundItemEntityMock.mock],
      decorations: [],
      buildings: [BuildingEntityMock.mock],
      stumps: [],
      rocks: [],
    );
  }

  static const WorldSnapshotEntity withAStump = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [TreeEntityMock.mock],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
    stumps: [StumpEntityMock.fresh],
    rocks: [],
  );

  static const WorldSnapshotEntity withARock = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [TreeEntityMock.mock],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
    stumps: [],
    rocks: [RockEntityMock.intact],
  );
}
