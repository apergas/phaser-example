import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../domain/entities/item/ground_item_entity_mock.dart';
import '../../../domain/entities/player/player_entity_mock.dart';
import '../../../domain/entities/tree/tree_entity_mock.dart';
import '../../../domain/world/world_mock.dart';

abstract final class ForestScenarioMock {
  static const PositionEntity groundEast = PositionEntity(x: 150, y: 100);
  static const PositionEntity playerStart = PositionEntity(x: 100, y: 100);
  static const PositionEntity eastTreeCanopy = PositionEntity(x: 300, y: 80);
  static const PositionEntity axeSpot = PositionEntity(x: 110, y: 100);
  static const PositionEntity treeCanopy = PositionEntity(x: 200, y: 80);
  static const PositionEntity siteNextToFarTree = PositionEntity(x: 410, y: 400);
  static const PositionEntity freeSite = PositionEntity(x: 250, y: 250);
  static const PositionEntity farSite = PositionEntity(x: 500, y: 500);
  static const PositionEntity houseSiteEast = PositionEntity(x: 300, y: 100);

  static World empty() => WorldMock.make();

  static World treeEast() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 300, y: 100))]);

  static World axeNextToPlayer() => WorldMock.make(items: [GroundItemEntityMock.mock.copyWith(position: axeSpot)]);

  static World axeInHandWithTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
    trees: [TreeEntityMock.mock],
  );

  static World tenWood() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(resources: {Resource.wood: 10})),
  );

  static World fifteenWood() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(resources: {Resource.wood: 15})),
  );

  static World fifteenWoodWithFarTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(resources: {Resource.wood: 15})),
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))],
  );

  static World axeAndFifteenWood() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(
      inventory: const InventoryEntity(resources: {Resource.wood: 15}, tools: {ToolKind.axe}),
    ),
  );
}
