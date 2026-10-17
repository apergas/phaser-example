import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/item/ground_item_entity.dart';

abstract final class GroundItemEntityMock {
  static const GroundItemEntity mock = GroundItemEntity(
    id: 'axe-1',
    kind: ToolKind.axe,
    position: PositionEntity(x: 150, y: 100),
  );
}
