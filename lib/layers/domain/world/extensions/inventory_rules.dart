import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';

extension InventoryRules on InventoryEntity {
  int amount(Resource resource) => resources[resource] ?? 0;

  InventoryEntity add(Resource resource, int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Cannot add a negative amount of ${resource.name}');
    }
    if (quantity == 0) return this;
    return copyWith(resources: {...resources, resource: amount(resource) + quantity});
  }

  Map<Resource, int> missing(Map<Resource, int> cost) {
    for (final MapEntry(key: resource, value: quantity) in cost.entries) {
      if (quantity < 0) {
        throw ArgumentError.value(quantity, 'cost', 'Cannot require a negative amount of ${resource.name}');
      }
    }
    return {
      for (final MapEntry(key: resource, value: quantity) in cost.entries)
        if (quantity > amount(resource)) resource: quantity - amount(resource),
    };
  }

  InventoryEntity? spend(Map<Resource, int> cost) {
    if (missing(cost).isNotEmpty) return null;
    final remaining = {
      ...resources,
      for (final MapEntry(key: resource, value: quantity) in cost.entries) resource: amount(resource) - quantity,
    }..removeWhere((_, quantity) => quantity == 0);
    return copyWith(resources: remaining);
  }

  InventoryEntity addTool(ToolKind tool) => copyWith(tools: {...tools, tool});

  bool hasTool(ToolKind tool) => tools.contains(tool);
}
