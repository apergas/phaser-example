import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/item/ground_item_entity_mock.dart';
import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class GameScenarioMock {
  static const PositionEntity axeSpot = PositionEntity(x: 110, y: 100);
  static const PositionEntity wholeLoopAxeSpot = PositionEntity(x: 125, y: 100);
  static const PositionEntity houseSite = PositionEntity(x: 400, y: 400);
  static const PositionEntity halfSwingTreeTarget = PositionEntity(x: 120, y: 100);
  static const PositionEntity playerDestination = PositionEntity(x: 50, y: 150);

  static World levelWithOneTree() => WorldMock.make(trees: [TreeEntityMock.mock]);

  static World playerAtFifty() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(position: const PositionEntity(x: 50, y: 50)));

  static World wholeLoop() => WorldMock.make(
    items: [GroundItemEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
    trees: [
      TreeEntityMock.mock,
      TreeEntityMock.mock.copyWith(id: 'tree-2', position: const PositionEntity(x: 200, y: 200)),
      TreeEntityMock.mock.copyWith(id: 'tree-3', position: const PositionEntity(x: 100, y: 200)),
    ],
  );

  static World axeNextToPlayer() =>
      WorldMock.make(items: [GroundItemEntityMock.mock.copyWith(position: const PositionEntity(x: 110, y: 100))]);

  static World axeInHandNextToTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
  );

  static World tenWood() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 10)));

  static World treeOnBuildingSite() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))]);
}
