import 'package:farming/layers/data/datasources/save/local/dbo/save_stock_dbo.dart';

abstract final class SaveStockDBOMock {
  static const SaveStockDBO stock = SaveStockDBO(resources: {'wood': 30, 'gold': 45, 'mana': 12, 'stone': 9});
  static const SaveStockDBO withTheVersionOneLoad = SaveStockDBO(
    resources: {'wood': 34, 'gold': 45, 'mana': 12, 'stone': 12},
  );
  static const SaveStockDBO onlyTheVersionOneLoad = SaveStockDBO(resources: {'wood': 4, 'stone': 3});
  static const SaveStockDBO empty = SaveStockDBO();
  static const SaveStockDBO withZeroResource = SaveStockDBO(resources: {'wood': 0, 'stone': 3});
  static const SaveStockDBO withUnknownResource = SaveStockDBO(resources: {'diamond': 1});
  static const SaveStockDBO withNegativeResource = SaveStockDBO(resources: {'wood': -1});
  static const Map<String, dynamic> wrongTypes = {
    'resources': {'wood': 'many'},
  };
  static const Map<String, dynamic> versionOneJson = {
    'resources': {'wood': 30, 'gold': 45, 'mana': 12, 'stone': 9},
    'tools': <String>[],
    'toolLevels': <String, int>{},
  };
}
