import 'package:rpg/layers/data/datasources/level/local/dbo/decoration_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/item_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/level_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/point_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';

abstract final class LevelDBOMock {
  static const PointDBO _playerStart = PointDBO(x: 200, y: 150);
  static const List<TreeDBO> _trees = [TreeDBO(id: 'tree-a', kind: 'oak', x: 50, y: 60, wood: 5)];
  static const List<ItemDBO> _items = [ItemDBO(id: 'axe', kind: 'axe', x: 220, y: 150)];
  static const List<DecorationDBO> _decorations = [
    DecorationDBO(id: 'decoration-a', kind: 'tall-grass', x: 300, y: 200),
  ];

  static const LevelDBO mock = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownItem = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: [ItemDBO(id: 'mystery', kind: 'laser', x: 0, y: 0)],
    decorations: _decorations,
  );

  static const LevelDBO mockWithoutSize = LevelDBO(
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownTreeKind = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: [TreeDBO(id: 'tree-x', kind: 'palm', x: 0, y: 0, wood: 5)],
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownDecorationKind = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: [DecorationDBO(id: 'decoration-x', kind: 'lava', x: 0, y: 0)],
  );
}
