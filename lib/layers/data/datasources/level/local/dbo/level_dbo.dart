import 'package:collection/collection.dart';

import 'decoration_dbo.dart';
import 'item_dbo.dart';
import 'point_dbo.dart';
import 'tree_dbo.dart';

class LevelDBO {
  final double? width;
  final double? height;
  final PointDBO? playerStart;
  final List<TreeDBO>? trees;
  final List<ItemDBO>? items;
  final List<DecorationDBO>? decorations;

  const LevelDBO({this.width, this.height, this.playerStart, this.trees, this.items, this.decorations});

  @override
  bool operator ==(Object other) =>
      other is LevelDBO &&
      other.width == width &&
      other.height == height &&
      other.playerStart == playerStart &&
      const ListEquality<TreeDBO>().equals(other.trees, trees) &&
      const ListEquality<ItemDBO>().equals(other.items, items) &&
      const ListEquality<DecorationDBO>().equals(other.decorations, decorations);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    playerStart,
    const ListEquality<TreeDBO>().hash(trees),
    const ListEquality<ItemDBO>().hash(items),
    const ListEquality<DecorationDBO>().hash(decorations),
  );

  @override
  String toString() =>
      'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, items: $items, '
      'decorations: $decorations)';
}
