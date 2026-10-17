import 'package:collection/collection.dart';

import 'building_dbo.dart';
import 'decoration_dbo.dart';
import 'item_dbo.dart';
import 'point_dbo.dart';
import 'rock_dbo.dart';
import 'tree_dbo.dart';

class LevelDBO {
  final double? width;
  final double? height;
  final PointDBO? playerStart;
  final List<TreeDBO>? trees;
  final List<ItemDBO>? items;
  final List<DecorationDBO>? decorations;
  final List<RockDBO>? rocks;
  final List<BuildingDBO>? buildings;

  const LevelDBO({
    this.width,
    this.height,
    this.playerStart,
    this.trees,
    this.items,
    this.decorations,
    this.rocks,
    this.buildings,
  });

  @override
  bool operator ==(Object other) =>
      other is LevelDBO &&
      other.width == width &&
      other.height == height &&
      other.playerStart == playerStart &&
      const ListEquality<TreeDBO>().equals(other.trees, trees) &&
      const ListEquality<ItemDBO>().equals(other.items, items) &&
      const ListEquality<DecorationDBO>().equals(other.decorations, decorations) &&
      const ListEquality<RockDBO>().equals(other.rocks, rocks) &&
      const ListEquality<BuildingDBO>().equals(other.buildings, buildings);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    playerStart,
    const ListEquality<TreeDBO>().hash(trees),
    const ListEquality<ItemDBO>().hash(items),
    const ListEquality<DecorationDBO>().hash(decorations),
    const ListEquality<RockDBO>().hash(rocks),
    const ListEquality<BuildingDBO>().hash(buildings),
  );

  @override
  String toString() =>
      'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, items: $items, '
      'decorations: $decorations, rocks: $rocks, buildings: $buildings)';
}
