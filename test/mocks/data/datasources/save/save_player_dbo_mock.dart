import 'package:farming/layers/data/datasources/save/local/dbo/save_player_dbo.dart';

import 'save_inventory_dbo_mock.dart';

abstract final class SavePlayerDBOMock {
  static const SavePlayerDBO mock = SavePlayerDBO(x: 420, y: 380, inventory: SaveInventoryDBOMock.player);
  static const SavePlayerDBO withoutInventory = SavePlayerDBO(x: 420, y: 380);
  static const SavePlayerDBO withoutX = SavePlayerDBO(y: 380);
  static const SavePlayerDBO withoutY = SavePlayerDBO(x: 420);
  static const SavePlayerDBO overloaded = SavePlayerDBO(x: 420, y: 380, inventory: SaveInventoryDBOMock.overCapacity);
  static const SavePlayerDBO atCapacity = SavePlayerDBO(x: 420, y: 380, inventory: SaveInventoryDBOMock.atCapacity);
  static const SavePlayerDBO withBadInventory = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.withUnknownResource,
  );
  static const SavePlayerDBO carryingGold = SavePlayerDBO(
    x: 420,
    y: 380,
    inventory: SaveInventoryDBOMock.goldDoesNotCarry,
  );
  static const Map<String, dynamic> wrongTypes = {'x': 420, 'y': 380, 'inventory': 'bag'};
}
