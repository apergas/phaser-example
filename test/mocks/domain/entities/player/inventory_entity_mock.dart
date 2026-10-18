import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';

abstract final class InventoryEntityMock {
  static const InventoryEntity mock = InventoryEntity();

  static const InventoryEntity withAxe = InventoryEntity(tools: {ToolKind.axe});

  static const InventoryEntity withIronAxe = InventoryEntity(tools: {ToolKind.axe}, toolLevels: {ToolKind.axe: 2});

  static const InventoryEntity withBothToolsAndIronAxe = InventoryEntity(
    tools: {ToolKind.axe, ToolKind.pickaxe},
    toolLevels: {ToolKind.axe: 2},
  );

  static InventoryEntity make({Set<ToolKind> tools = const {}, Map<ToolKind, int> toolLevels = const {}}) =>
      InventoryEntity(tools: tools, toolLevels: toolLevels);
}
