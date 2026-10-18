import 'package:farming/layers/data/datasources/save/local/dbo/save_building_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_player_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_stock_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_tree_dbo.dart';

import 'save_building_dbo_mock.dart';
import 'save_decoration_dbo_mock.dart';
import 'save_hero_dbo_mock.dart';
import 'save_item_dbo_mock.dart';
import 'save_player_dbo_mock.dart';
import 'save_rock_dbo_mock.dart';
import 'save_stats_dbo_mock.dart';
import 'save_stock_dbo_mock.dart';
import 'save_stump_dbo_mock.dart';
import 'save_tree_dbo_mock.dart';

abstract final class SaveDBOMock {
  static const List<String> _quests = ['gatherWood', 'buildHouse', 'buildForge'];
  static const List<String> _versionOneQuests = ['gatherWood', 'buildHouse', 'buildQuarry', 'buildForge'];
  static const List<SaveBuildingDBO> _buildings = [
    SaveBuildingDBOMock.house,
    SaveBuildingDBOMock.finishedHouse,
    SaveBuildingDBOMock.forgeSite,
  ];
  static const List<SaveBuildingDBO> _versionOneBuildings = [
    SaveBuildingDBOMock.house,
    SaveBuildingDBOMock.finishedHouse,
    SaveBuildingDBOMock.storehouse,
    SaveBuildingDBOMock.forgeSite,
    SaveBuildingDBOMock.quarrySite,
  ];

  static SaveDBO _build({
    int? version = SaveDBO.currentVersion,
    double? width = 1600,
    double? height = 1200,
    SavePlayerDBO? player = SavePlayerDBOMock.mock,
    SaveStockDBO? stock = SaveStockDBOMock.stock,
    List<SaveBuildingDBO>? buildings = _buildings,
    List<SaveTreeDBO>? trees = const [SaveTreeDBOMock.withThreeHitsTaken, SaveTreeDBOMock.neighbour],
    Map<String, int>? idCounters = const {'building': 3},
    List<String>? completedQuests = _quests,
  }) {
    return SaveDBO(
      version: version,
      width: width,
      height: height,
      player: player,
      hero: SaveHeroDBOMock.mock,
      stats: SaveStatsDBOMock.mock,
      stock: stock,
      trees: trees,
      stumps: const [SaveStumpDBOMock.elsewhereAlmostSapling, SaveStumpDBOMock.otherSapling],
      rocks: const [SaveRockDBOMock.onceHit],
      items: const [SaveItemDBOMock.axe],
      decorations: const [SaveDecorationDBOMock.rock],
      buildings: buildings,
      idCounters: idCounters,
      completedQuests: completedQuests,
    );
  }

  static final SaveDBO everything = _build();
  static final SaveDBO sameAsEverything = _build();
  static final SaveDBO otherVersion = _build(version: 3);
  static final SaveDBO versionOne = _build(
    version: 1,
    player: SavePlayerDBOMock.versionOne,
    stock: SaveStockDBOMock.stock,
    buildings: _versionOneBuildings,
    completedQuests: _versionOneQuests,
  );
  static final SaveDBO versionOneMigrated = _build(stock: SaveStockDBOMock.withTheVersionOneLoad);
  static final SaveDBO versionOneWithoutStock = _build(version: 1, player: SavePlayerDBOMock.versionOne, stock: null);
  static final SaveDBO versionOneWithNegativeCarry = _build(
    version: 1,
    player: SavePlayerDBOMock.versionOneWithNegativeCarry,
  );
  static final SaveDBO withoutVersion = _build(version: null);
  static final SaveDBO withoutWidth = _build(width: null);
  static final SaveDBO withZeroWidth = _build(width: 0);
  static final SaveDBO withoutHeight = _build(height: null);
  static final SaveDBO withNegativeHeight = _build(height: -5);
  static final SaveDBO withoutPlayer = _build(player: null);
  static final SaveDBO withOtherTrees = _build(trees: const [SaveTreeDBOMock.neighbour]);
  static final SaveDBO withBadTree = _build(trees: const [SaveTreeDBOMock.withAllHits]);
  static final SaveDBO withOtherCounters = _build(idCounters: const {'building': 4});
  static final SaveDBO withNegativeCounter = _build(idCounters: const {'building': -1});
  static final SaveDBO withOtherQuests = _build(completedQuests: const ['gatherWood']);
  static final SaveDBO withUnknownQuest = _build(completedQuests: const ['saveTheWorld']);
  static final SaveDBO withNothingElse = _build(trees: null, idCounters: null, completedQuests: null);
  static const SaveDBO onlyWorldSize = SaveDBO(
    version: SaveDBO.currentVersion,
    width: 400,
    height: 300,
    player: SavePlayerDBOMock.mock,
  );
  static const Map<String, dynamic> wrongTypes = {'version': '1'};
  static const Map<String, dynamic> wrongTreesType = {'trees': 'many'};
  static const Map<String, dynamic> wrongTreeItemType = {
    'trees': [3],
  };
  static const Map<String, dynamic> wrongPlayerType = {'player': 3};
  static const Map<String, dynamic> wrongIdCountersType = {
    'idCounters': {'building': '3'},
  };
  static const Map<String, dynamic> wrongQuestsType = {
    'completedQuests': [3],
  };
}
