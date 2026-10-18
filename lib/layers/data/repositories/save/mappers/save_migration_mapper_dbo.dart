import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../datasources/save/local/dbo/save_building_dbo.dart';
import '../../../datasources/save/local/dbo/save_dbo.dart';
import '../../../datasources/save/local/dbo/save_inventory_dbo.dart';
import '../../../datasources/save/local/dbo/save_player_dbo.dart';
import '../../../datasources/save/local/dbo/save_stock_dbo.dart';

@Injectable()
class SaveMigrationMapperDBO {
  static const Set<String> _removedBlueprints = {'storehouse', 'quarry'};
  static const Set<String> _removedQuests = {'buildQuarry'};

  SaveDBO toCurrent(SaveDBO dbo) => switch (dbo.version) {
    SaveDBO.currentVersion => dbo,
    1 => _fromVersionOne(dbo),
    _ => throw InvalidSaveException(data: 'unknown version ${dbo.version}'),
  };

  SaveDBO _fromVersionOne(SaveDBO dbo) {
    final player = dbo.player;
    final inventory = player?.inventory;
    final carried = inventory?.resources ?? const <String, int>{};
    for (final MapEntry(key: resource, value: amount) in carried.entries) {
      if (amount < 0) throw InvalidSaveException(data: 'player: $amount $resource');
    }
    return SaveDBO(
      version: SaveDBO.currentVersion,
      width: dbo.width,
      height: dbo.height,
      player: player == null
          ? null
          : SavePlayerDBO(
              x: player.x,
              y: player.y,
              inventory: inventory == null
                  ? null
                  : SaveInventoryDBO(tools: inventory.tools, toolLevels: inventory.toolLevels),
            ),
      hero: dbo.hero,
      stats: dbo.stats,
      stock: _withCarried(dbo.stock, carried),
      trees: dbo.trees,
      stumps: dbo.stumps,
      rocks: dbo.rocks,
      items: dbo.items,
      decorations: dbo.decorations,
      buildings: dbo.buildings?.where(_isKept).toList(),
      idCounters: dbo.idCounters,
      completedQuests: dbo.completedQuests?.where((quest) => !_removedQuests.contains(quest)).toList(),
    );
  }

  SaveStockDBO? _withCarried(SaveStockDBO? stock, Map<String, int> carried) {
    if (carried.isEmpty) return stock;
    final resources = {...?stock?.resources};
    for (final MapEntry(key: resource, value: amount) in carried.entries) {
      resources[resource] = (resources[resource] ?? 0) + amount;
    }
    return SaveStockDBO(resources: resources);
  }

  bool _isKept(SaveBuildingDBO building) => !_removedBlueprints.contains(building.blueprint);
}
