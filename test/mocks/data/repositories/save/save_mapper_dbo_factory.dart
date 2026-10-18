import 'package:farming/layers/data/repositories/save/mappers/save_building_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_decoration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_hero_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_inventory_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_migration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_player_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_rock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stats_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stump_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_tree_mapper_dbo.dart';

SaveMapperDBO makeSaveMapperDBO() {
  final positionMapperDBO = SavePositionMapperDBO();
  final inventoryMapperDBO = SaveInventoryMapperDBO();
  return SaveMapperDBO(
    treeMapperDBO: SaveTreeMapperDBO(positionMapperDBO: positionMapperDBO),
    stumpMapperDBO: SaveStumpMapperDBO(positionMapperDBO: positionMapperDBO),
    rockMapperDBO: SaveRockMapperDBO(positionMapperDBO: positionMapperDBO),
    decorationMapperDBO: SaveDecorationMapperDBO(positionMapperDBO: positionMapperDBO),
    buildingMapperDBO: SaveBuildingMapperDBO(positionMapperDBO: positionMapperDBO),
    stockMapperDBO: SaveStockMapperDBO(),
    migrationMapperDBO: SaveMigrationMapperDBO(),
    playerMapperDBO: SavePlayerMapperDBO(positionMapperDBO: positionMapperDBO, inventoryMapperDBO: inventoryMapperDBO),
    heroMapperDBO: SaveHeroMapperDBO(),
    statsMapperDBO: SaveStatsMapperDBO(),
  );
}
