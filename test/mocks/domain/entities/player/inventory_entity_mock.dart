import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';

abstract final class InventoryEntityMock {
  static const InventoryEntity mock = InventoryEntity();

  static const InventoryEntity withWood = InventoryEntity(wood: 6);

  static const InventoryEntity withAxe = InventoryEntity(tools: {ToolKind.axe});

  static InventoryEntity make({int wood = 0, Set<ToolKind> tools = const {}}) =>
      InventoryEntity(wood: wood, tools: tools);
}
