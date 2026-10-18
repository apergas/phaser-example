import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/quest_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/game/game_session_entity.dart';
import '../../../../domain/quests/quest_log.dart';
import '../../../../domain/world/world.dart';
import '../../../datasources/save/local/dbo/save_dbo.dart';
import 'save_building_mapper_dbo.dart';
import 'save_decoration_mapper_dbo.dart';
import 'save_ground_item_mapper_dbo.dart';
import 'save_hero_mapper_dbo.dart';
import 'save_migration_mapper_dbo.dart';
import 'save_player_mapper_dbo.dart';
import 'save_rock_mapper_dbo.dart';
import 'save_stock_mapper_dbo.dart';
import 'save_stats_mapper_dbo.dart';
import 'save_stump_mapper_dbo.dart';
import 'save_tree_mapper_dbo.dart';

@Injectable()
class SaveMapperDBO {
  final SaveTreeMapperDBO _treeMapperDBO;
  final SaveStumpMapperDBO _stumpMapperDBO;
  final SaveRockMapperDBO _rockMapperDBO;
  final SaveGroundItemMapperDBO _groundItemMapperDBO;
  final SaveDecorationMapperDBO _decorationMapperDBO;
  final SaveBuildingMapperDBO _buildingMapperDBO;
  final SaveStockMapperDBO _stockMapperDBO;
  final SaveMigrationMapperDBO _migrationMapperDBO;
  final SavePlayerMapperDBO _playerMapperDBO;
  final SaveHeroMapperDBO _heroMapperDBO;
  final SaveStatsMapperDBO _statsMapperDBO;

  const SaveMapperDBO({
    required this._treeMapperDBO,
    required this._stumpMapperDBO,
    required this._rockMapperDBO,
    required this._groundItemMapperDBO,
    required this._decorationMapperDBO,
    required this._buildingMapperDBO,
    required this._stockMapperDBO,
    required this._migrationMapperDBO,
    required this._playerMapperDBO,
    required this._heroMapperDBO,
    required this._statsMapperDBO,
  });

  SaveDBO toDBO(GameSessionEntity session) {
    final world = session.world;
    final completed = session.quests.completed;
    return SaveDBO(
      version: SaveDBO.currentVersion,
      width: world.width,
      height: world.height,
      player: _playerMapperDBO.toDBO(world.player),
      hero: _heroMapperDBO.toDBO(world.hero),
      stats: _statsMapperDBO.toDBO(world.stats),
      stock: _stockMapperDBO.toDBO(world.stock),
      trees: world.trees.map(_treeMapperDBO.toDBO).toList(),
      stumps: world.stumps.map(_stumpMapperDBO.toDBO).toList(),
      rocks: world.rocks.map(_rockMapperDBO.toDBO).toList(),
      items: world.items.map(_groundItemMapperDBO.toDBO).toList(),
      decorations: world.decorations.map(_decorationMapperDBO.toDBO).toList(),
      buildings: world.buildings.map(_buildingMapperDBO.toDBO).toList(),
      idCounters: {...world.idCounters},
      completedQuests: [
        for (final id in QuestId.values)
          if (completed.contains(id)) id.name,
      ],
    );
  }

  GameSessionEntity toEntity(SaveDBO saved) {
    final dbo = _migrationMapperDBO.toCurrent(saved);
    return GameSessionEntity(
      world: World.restore(
        width: _size(dbo.width, 'width'),
        height: _size(dbo.height, 'height'),
        player: _playerMapperDBO.toEntity(dbo.player),
        trees: (dbo.trees ?? const []).map(_treeMapperDBO.toEntity).toList(),
        stumps: (dbo.stumps ?? const []).map(_stumpMapperDBO.toEntity).toList(),
        rocks: (dbo.rocks ?? const []).map(_rockMapperDBO.toEntity).toList(),
        items: (dbo.items ?? const []).map(_groundItemMapperDBO.toEntity).toList(),
        decorations: (dbo.decorations ?? const []).map(_decorationMapperDBO.toEntity).toList(),
        buildings: (dbo.buildings ?? const []).map(_buildingMapperDBO.toEntity).toList(),
        hero: _heroMapperDBO.toEntity(dbo.hero),
        stats: _statsMapperDBO.toEntity(dbo.stats),
        stock: _stockMapperDBO.toEntity(dbo.stock),
        idCounters: _idCounters(dbo.idCounters ?? const {}),
      ),
      quests: QuestLog(
        completed: {
          for (final name in dbo.completedQuests ?? const <String>[])
            QuestId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'unknown quest "$name"')),
        },
      ),
    );
  }

  double _size(double? size, String field) {
    if (size == null || size <= 0) throw InvalidSaveException(data: 'world $field $size');
    return size;
  }

  Map<String, int> _idCounters(Map<String, int> counters) {
    for (final MapEntry(key: prefix, value: count) in counters.entries) {
      if (count < 0) throw InvalidSaveException(data: 'id counter $prefix $count');
    }
    return counters;
  }
}
