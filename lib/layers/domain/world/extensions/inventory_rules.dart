import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';

extension InventoryRules on InventoryEntity {
  InventoryEntity addWood(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount', 'Cannot add a negative amount of wood');
    return copyWith(wood: wood + amount);
  }

  InventoryEntity? spendWood(int amount) => amount > wood ? null : copyWith(wood: wood - amount);

  InventoryEntity addTool(ToolKind tool) => copyWith(tools: {...tools, tool});

  bool hasTool(ToolKind tool) => tools.contains(tool);
}
