import 'package:collection/collection.dart';

import '../building/building_entity.dart';
import '../decoration/decoration_entity.dart';
import '../rock/rock_entity.dart';
import '../tree/stump_entity.dart';
import '../tree/tree_entity.dart';

class WorldSnapshotEntity {
  final double width;
  final double height;
  final List<TreeEntity> trees;
  final List<DecorationEntity> decorations;
  final List<BuildingEntity> buildings;
  final List<StumpEntity> stumps;
  final List<RockEntity> rocks;

  const WorldSnapshotEntity({
    required this.width,
    required this.height,
    required this.trees,
    required this.decorations,
    required this.buildings,
    required this.stumps,
    required this.rocks,
  });

  @override
  bool operator ==(Object other) =>
      other is WorldSnapshotEntity &&
      other.width == width &&
      other.height == height &&
      const ListEquality<TreeEntity>().equals(other.trees, trees) &&
      const ListEquality<DecorationEntity>().equals(other.decorations, decorations) &&
      const ListEquality<BuildingEntity>().equals(other.buildings, buildings) &&
      const ListEquality<StumpEntity>().equals(other.stumps, stumps) &&
      const ListEquality<RockEntity>().equals(other.rocks, rocks);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    const ListEquality<TreeEntity>().hash(trees),
    const ListEquality<DecorationEntity>().hash(decorations),
    const ListEquality<BuildingEntity>().hash(buildings),
    const ListEquality<StumpEntity>().hash(stumps),
    const ListEquality<RockEntity>().hash(rocks),
  );
}
