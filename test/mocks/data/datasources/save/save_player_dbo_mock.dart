import 'package:farming/layers/data/datasources/save/local/dbo/save_player_dbo.dart';

import 'save_inventory_dbo_mock.dart';

abstract final class SavePlayerDBOMock {
  static const SavePlayerDBO mock = SavePlayerDBO(x: 420, y: 380, inventory: SaveInventoryDBOMock.player);
  static const SavePlayerDBO versionOne = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.versionOnePlayer,
  );
  static const SavePlayerDBO versionOneWithNegativeCarry = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.versionOneWithNegativeCarry,
  );
  static const SavePlayerDBO withoutPickaxe = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.withoutPickaxe,
  );
  static const SavePlayerDBO withOnlyThePickaxe = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.onlyThePickaxe,
  );
  static const SavePlayerDBO withoutInventory = SavePlayerDBO(x: 420, y: 380);
  static const SavePlayerDBO withoutX = SavePlayerDBO(y: 380);
  static const SavePlayerDBO withoutY = SavePlayerDBO(x: 420);
  static const SavePlayerDBO withBadInventory = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.withUnknownTool,
  );
  static const Map<String, dynamic> wrongTypes = {'x': 420, 'y': 380, 'inventory': 'bag'};
}
