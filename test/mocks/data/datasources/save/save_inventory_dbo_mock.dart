import 'package:farming/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart';

abstract final class SaveInventoryDBOMock {
  static const SaveInventoryDBO player = SaveInventoryDBO(
    tools: ['axe', 'pickaxe'],
    toolLevels: {'axe': 2},
  );
  static const SaveInventoryDBO stock = SaveInventoryDBO(
    resources: {'wood': 30, 'gold': 45, 'mana': 12, 'stone': 9},
    tools: [],
    toolLevels: {},
  );
  static const SaveInventoryDBO empty = SaveInventoryDBO();
  static const SaveInventoryDBO withZeroResource = SaveInventoryDBO(resources: {'wood': 0, 'stone': 3});
  static const SaveInventoryDBO withUnknownResource = SaveInventoryDBO(resources: {'diamond': 1});
  static const SaveInventoryDBO withNegativeResource = SaveInventoryDBO(resources: {'wood': -1});
  static const SaveInventoryDBO withUnknownTool = SaveInventoryDBO(tools: ['hammer']);
  static const SaveInventoryDBO withUnknownToolLevel = SaveInventoryDBO(toolLevels: {'hammer': 2});
  static const SaveInventoryDBO withToolLevelZero = SaveInventoryDBO(toolLevels: {'axe': 0});
  static const SaveInventoryDBO withToolLevelBeyondTheMaximum = SaveInventoryDBO(
    tools: ['axe', 'pickaxe'],
    toolLevels: {'axe': 7, 'pickaxe': 2},
  );
  static const Map<String, dynamic> wrongTypes = {
    'resources': {'wood': 'many'},
  };
  static const Map<String, dynamic> wrongListType = {'tools': 'axe'};
  static const Map<String, dynamic> wrongToolListItem = {
    'tools': [1],
  };
}
