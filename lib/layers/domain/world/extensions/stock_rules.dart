import '../../../../core/config/constants/enum/resource.dart';
import '../../entities/stock/stock_entity.dart';

extension StockRules on StockEntity {
  int amount(Resource resource) => resources[resource] ?? 0;

  StockEntity add(Resource resource, int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Cannot add a negative amount of ${resource.name}');
    }
    if (quantity == 0) return this;
    return copyWith(resources: {...resources, resource: amount(resource) + quantity});
  }

  StockEntity adding(Map<Resource, int> amounts) {
    var stock = this;
    for (final resource in Resource.values) {
      final quantity = amounts[resource] ?? 0;
      if (quantity > 0) stock = stock.add(resource, quantity);
    }
    return stock;
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

  StockEntity? spend(Map<Resource, int> cost) {
    if (missing(cost).isNotEmpty) return null;
    final remaining = {
      ...resources,
      for (final MapEntry(key: resource, value: quantity) in cost.entries) resource: amount(resource) - quantity,
    }..removeWhere((_, quantity) => quantity == 0);
    return copyWith(resources: remaining);
  }
}
