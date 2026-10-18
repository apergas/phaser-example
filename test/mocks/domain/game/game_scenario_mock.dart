import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../entities/item/ground_item_entity_mock.dart';
import '../entities/player/player_entity_mock.dart';
import '../entities/rock/rock_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';
import '../world/world_mock.dart';

import '../entities/building/building_entity_mock.dart';

abstract final class GameScenarioMock {
  static const PositionEntity wholeLoopAxeSpot = PositionEntity(x: 125, y: 100);
  static const PositionEntity houseSite = PositionEntity(x: 400, y: 400);
  static const PositionEntity wholeLoopCampSite = PositionEntity(x: 300, y: 250);
  static const String wholeLoopCampId = 'level-building-1';
  static const PositionEntity halfSwingTreeTarget = PositionEntity(x: 120, y: 100);
  static const PositionEntity playerDestination = PositionEntity(x: 50, y: 150);

  static World levelWithOneTree() => WorldMock.make(trees: [TreeEntityMock.mock]);

  static World playerAtFifty() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(position: const PositionEntity(x: 50, y: 50)));

  static World wholeLoop() => WorldMock.make(
    items: [GroundItemEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
    buildings: [BuildingEntityMock.completed(Blueprints.camp, id: wholeLoopCampId, position: wholeLoopCampSite)],
    trees: [
      TreeEntityMock.mock,
      TreeEntityMock.mock.copyWith(id: 'tree-2', position: const PositionEntity(x: 200, y: 200)),
      TreeEntityMock.mock.copyWith(id: 'tree-3', position: const PositionEntity(x: 100, y: 200)),
    ],
  );

  static World axeInHandNextToTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
  );

  static World tenWoodInStock() => WorldMock.withStock(const {Resource.wood: 10});

  static World besideARock() => WorldMock.make(rocks: [RockEntityMock.intact]);

  static World treeOnBuildingSite() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))]);
}
