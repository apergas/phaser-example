import 'package:collection/collection.dart';

import '../building/building_entity.dart';
import '../decoration/decoration_entity.dart';
import '../item/ground_item_entity.dart';
import '../tree/tree_entity.dart';

class WorldSnapshotEntity {
  final double width;
  final double height;
  final List<TreeEntity> trees;
  final List<GroundItemEntity> items;
  final List<DecorationEntity> decorations;
  final List<BuildingEntity> buildings;

  const WorldSnapshotEntity({
    required this.width,
    required this.height,
    required this.trees,
    required this.items,
    required this.decorations,
    required this.buildings,
  });

  @override
  bool operator ==(Object other) =>
      other is WorldSnapshotEntity &&
      other.width == width &&
      other.height == height &&
      const ListEquality<TreeEntity>().equals(other.trees, trees) &&
      const ListEquality<GroundItemEntity>().equals(other.items, items) &&
      const ListEquality<DecorationEntity>().equals(other.decorations, decorations) &&
      const ListEquality<BuildingEntity>().equals(other.buildings, buildings);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    const ListEquality<TreeEntity>().hash(trees),
    const ListEquality<GroundItemEntity>().hash(items),
    const ListEquality<DecorationEntity>().hash(decorations),
    const ListEquality<BuildingEntity>().hash(buildings),
  );
}
