import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';

import '../building/building_entity_mock.dart';
import '../item/ground_item_entity_mock.dart';
import '../tree/tree_entity_mock.dart';

abstract final class WorldSnapshotEntityMock {
  static const WorldSnapshotEntity mock = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [TreeEntityMock.mock],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
  );
}
