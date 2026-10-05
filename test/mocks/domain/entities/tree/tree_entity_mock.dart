import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';

abstract final class TreeEntityMock {
  static const TreeEntity mock = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 200, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static const TreeEntity neighbour = TreeEntity(
    id: 'neighbour',
    kind: TreeKind.oak,
    position: PositionEntity(x: 165, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static const TreeEntity inTheWay = TreeEntity(
    id: 'in-the-way',
    kind: TreeKind.oak,
    position: PositionEntity(x: 180, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static const TreeEntity farEast = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 300, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static const TreeEntity blockingPath = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 130, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static const TreeEntity atSite = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 400, y: 400),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );

  static TreeEntity make({int woodYield = 6, int hitsToFell = 5}) {
    return TreeEntity(
      id: 'tree-1',
      kind: TreeKind.oak,
      position: const PositionEntity(x: 0, y: 0),
      trunkRadius: 10,
      woodYield: woodYield,
      hitsToFell: hitsToFell,
    );
  }
}
