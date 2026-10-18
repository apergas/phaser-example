import 'package:farming/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart';

abstract final class SaveInventoryDBOMock {
  static const SaveInventoryDBO player = SaveInventoryDBO(
    tools: ['axe', 'pickaxe'],
    toolLevels: {'axe': 2},
  );
  static const SaveInventoryDBO withoutPickaxe = SaveInventoryDBO(tools: ['axe'], toolLevels: {'axe': 2});
  static const SaveInventoryDBO onlyThePickaxe = SaveInventoryDBO(tools: ['pickaxe']);
  static const SaveInventoryDBO versionOnePlayer = SaveInventoryDBO(
    resources: {'wood': 4, 'stone': 3},
    tools: ['axe'],
    toolLevels: {'axe': 2},
  );
  static const SaveInventoryDBO versionOneWithNegativeCarry = SaveInventoryDBO(
    resources: {'wood': -1},
    tools: ['axe'],
  );
  static const SaveInventoryDBO empty = SaveInventoryDBO();
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
