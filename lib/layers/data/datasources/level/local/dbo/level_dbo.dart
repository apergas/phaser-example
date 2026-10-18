import 'package:collection/collection.dart';

import 'decoration_dbo.dart';
import 'point_dbo.dart';
import 'rock_dbo.dart';
import 'tree_dbo.dart';

class LevelDBO {
  final double? width;
  final double? height;
  final PointDBO? playerStart;
  final List<TreeDBO>? trees;
  final List<DecorationDBO>? decorations;
  final List<RockDBO>? rocks;

  const LevelDBO({
    this.width,
    this.height,
    this.playerStart,
    this.trees,
    this.decorations,
    this.rocks,
  });

  @override
  bool operator ==(Object other) =>
      other is LevelDBO &&
      other.width == width &&
      other.height == height &&
      other.playerStart == playerStart &&
      const ListEquality<TreeDBO>().equals(other.trees, trees) &&
      const ListEquality<DecorationDBO>().equals(other.decorations, decorations) &&
      const ListEquality<RockDBO>().equals(other.rocks, rocks);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    playerStart,
    const ListEquality<TreeDBO>().hash(trees),
    const ListEquality<DecorationDBO>().hash(decorations),
    const ListEquality<RockDBO>().hash(rocks),
  );

  @override
  String toString() =>
      'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, '
      'decorations: $decorations, rocks: $rocks)';
}
