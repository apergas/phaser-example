import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/resource.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/stock/stock_entity.dart';
import '../../../../domain/world/extensions/stock_rules.dart';
import '../../../datasources/save/local/dbo/save_stock_dbo.dart';

@Injectable()
class SaveStockMapperDBO {
  SaveStockDBO toDBO(StockEntity stock) {
    return SaveStockDBO(
      resources: {for (final MapEntry(key: resource, value: amount) in stock.resources.entries) resource.name: amount},
    );
  }

  StockEntity toEntity(SaveStockDBO? dbo) {
    if (dbo == null) return const StockEntity();
    var stock = const StockEntity();
    for (final MapEntry(key: name, value: amount) in (dbo.resources ?? const <String, int>{}).entries) {
      final resource =
          Resource.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'stock: unknown resource "$name"'));
      if (amount < 0) throw InvalidSaveException(data: 'stock: $amount ${resource.name}');
      stock = stock.add(resource, amount);
    }
    return stock;
  }
}
