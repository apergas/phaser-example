import 'dart:math';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';
import '../../rules/rules.dart';
import 'resource_rules.dart';

extension InventoryRules on InventoryEntity {
  int get load =>
      Resource.values.where((resource) => resource.takesCargo).fold(0, (sum, resource) => sum + amount(resource));

  int get freeLoad => max(0, Rules.carryCapacity - load);

  bool get isLoadFull => freeLoad == 0;

  Map<Resource, int> get cargo => {
    for (final resource in Resource.values)
      if (resource.takesCargo && amount(resource) > 0) resource: amount(resource),
  };

  int amount(Resource resource) => resources[resource] ?? 0;

  InventoryEntity add(Resource resource, int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Cannot add a negative amount of ${resource.name}');
    }
    if (quantity == 0) return this;
    return copyWith(resources: {...resources, resource: amount(resource) + quantity});
  }

  InventoryEntity adding(Map<Resource, int> amounts) {
    var inventory = this;
    for (final resource in Resource.values) {
      final quantity = amounts[resource] ?? 0;
      if (quantity > 0) inventory = inventory.add(resource, quantity);
    }
    return inventory;
  }

  InventoryEntity unloading() => copyWith(resources: {...resources}..removeWhere((resource, _) => resource.takesCargo));

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
