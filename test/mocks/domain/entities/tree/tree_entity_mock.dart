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
}
