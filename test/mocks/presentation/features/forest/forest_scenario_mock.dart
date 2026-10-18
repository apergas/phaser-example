import 'package:farming/layers/domain/entities/stock/stock_entity.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/game/stats_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../domain/entities/building/building_entity_mock.dart';
import '../../../domain/entities/item/ground_item_entity_mock.dart';
import '../../../domain/entities/player/player_entity_mock.dart';
import '../../../domain/entities/rock/rock_entity_mock.dart';
import '../../../domain/entities/tree/stump_entity_mock.dart';
import '../../../domain/entities/tree/tree_entity_mock.dart';
import '../../../domain/game/upgrade_scenario_mock.dart';
import '../../../domain/world/world_mock.dart';

abstract final class ForestScenarioMock {
  static const PositionEntity groundEast = PositionEntity(x: 150, y: 100);
  static const PositionEntity playerStart = PositionEntity(x: 100, y: 100);
  static const PositionEntity eastTreeCanopy = PositionEntity(x: 300, y: 80);
  static const PositionEntity pickaxeSpot = PositionEntity(x: 110, y: 100);
  static const PositionEntity treeCanopy = PositionEntity(x: 200, y: 80);
  static const PositionEntity siteNextToFarTree = PositionEntity(x: 410, y: 400);
  static const PositionEntity freeSite = PositionEntity(x: 250, y: 250);
  static const PositionEntity farSite = PositionEntity(x: 500, y: 500);
  static const PositionEntity houseSiteEast = PositionEntity(x: 300, y: 100);
  static const PositionEntity secondHouseSite = PositionEntity(x: 300, y: 300);
  static const PositionEntity rockSpot = PositionEntity(x: 300, y: 100);
  static const PositionEntity nearTheRock = PositionEntity(x: 300, y: 200);
  static const PositionEntity farFromTheRock = PositionEntity(x: 300, y: 450);
  static const String campId = 'camp';

  static const PlayerEntity withAxe = PlayerEntityMock.withAxe;

  static const StatsEntity tenVillageQuestStats = StatsEntity(
    treesFelled: 10,
    treesFelledByKind: {TreeKind.oak: 1, TreeKind.pine: 9},
    treesRegrown: 1,
  );

  static World empty() => WorldMock.make(player: withAxe);

  static World treeEast() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 300, y: 100))]);

  static World pickaxeNextToPlayer() => WorldMock.make(
    player: withAxe,
    items: [GroundItemEntityMock.pickaxe.copyWith(position: pickaxeSpot)],
  );

  static World pickaxeOnThePlayer() => WorldMock.make(
    player: withAxe,
    items: [GroundItemEntityMock.pickaxe.copyWith(position: playerStart)],
  );

  static World axeInHandWithTree() => WorldMock.make(player: withAxe, trees: [TreeEntityMock.mock]);

  static World tenWood() => WorldMock.withStock(const {Resource.wood: 10}, player: withAxe);

  static World fifteenWood() => WorldMock.withStock(const {Resource.wood: 15}, player: withAxe);

  static World fifteenWoodWithFarTree() => WorldMock.make(
    player: withAxe,
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))],
  )..earn(const {Resource.wood: 15});

  static World axeAndFifteenWood() => fifteenWood();

  static World oneHouseShortOfTheVillage() => WorldMock.restored(
    player: withAxe.copyWith(
      inventory: const InventoryEntity(tools: {ToolKind.axe}, toolLevels: {ToolKind.axe: 2}),
    ),
    buildings: [
      BuildingEntityMock.completed(Blueprints.house, id: 'building-1', position: const PositionEntity(x: 600, y: 600)),
      BuildingEntityMock.completed(Blueprints.quarry, id: 'building-2', position: const PositionEntity(x: 800, y: 600)),
      BuildingEntityMock.completed(
        Blueprints.workshop,
        id: 'building-3',
        position: const PositionEntity(x: 600, y: 800),
      ),
    ],
    stats: tenVillageQuestStats,
    stock: const StockEntity(resources: {Resource.wood: 55, Resource.stone: 20}),
    idCounters: const {'building': 3},
  );

  static World pickaxeAndRock() => WorldMock.make(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);

  static World rockWithoutPickaxe() => WorldMock.make(player: withAxe, rocks: [RockEntityMock.intact]);

  static World rockInFrontOfATree() => WorldMock.make(
    player: PlayerEntityMock.withPickaxe,
    rocks: [RockEntityMock.intact],
    trees: [TreeEntityMock.farEast],
  );

  static World atTheCamp() => WorldMock.make(player: withAxe, buildings: [BuildingEntityMock.camp]);

  static World campAndARock() => WorldMock.make(
    player: PlayerEntityMock.withPickaxe,
    buildings: [BuildingEntityMock.camp.copyWith(position: const PositionEntity(x: 300, y: 300))],
    rocks: [RockEntityMock.intact],
  );

  static World houseSiteAndARock() => WorldMock.make(
    player: PlayerEntityMock.withPickaxe,
    buildings: [BuildingEntityMock.site(Blueprints.house, id: 'house', position: const PositionEntity(x: 300, y: 300))],
    rocks: [RockEntityMock.intact],
  );

  static World nextToAFinishedHouse() => WorldMock.make(player: withAxe, buildings: [BuildingEntityMock.finishedHouse]);

  static World nextToAHouseSite() => WorldMock.make(
    player: withAxe,
    buildings: [BuildingEntityMock.site(Blueprints.house, id: 'house', position: BuildingEntityMock.dropOffSite)],
  );

  static World fifteenWoodAndAHouse() => WorldMock.restored(
    player: withAxe,
    buildings: [
      BuildingEntityMock.completed(Blueprints.house, id: 'building-1', position: const PositionEntity(x: 600, y: 600)),
    ],
    stock: const StockEntity(resources: {Resource.wood: 15}),
  );

  static World ironAxeWithoutWorkshop() => WorldMock.make(player: PlayerEntityMock.withIronAxe);

  static World quarryPriceAndARock() =>
      WorldMock.make(player: withAxe, rocks: [RockEntityMock.intact])..earn(const {Resource.wood: 25});

  static World stumpAboutToSprout() => WorldMock.restored(player: withAxe, stumps: [StumpEntityMock.almostSapling]);

  static World stumpAboutToRegrow() => WorldMock.restored(player: withAxe, stumps: [StumpEntityMock.almostReady]);

  static World workshopWith(Map<Resource, int> stock, {PlayerEntity player = withAxe}) =>
      UpgradeScenarioMock.withWorkshop(stock: stock, player: player);
}
