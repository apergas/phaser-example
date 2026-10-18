import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/building/building_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../entities/building/building_entity_mock.dart';
import '../entities/player/player_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class UpgradeScenarioMock {
  static const PositionEntity workshopPosition = PositionEntity(x: 600, y: 600);

  static const Map<Resource, int> ironAxePrice = {Resource.wood: 15, Resource.stone: 15};

  static const Map<Resource, int> ironPickaxePrice = {Resource.wood: 10, Resource.stone: 20};

  static const Map<Resource, int> fiveStoneShortOfTheIronAxe = {Resource.wood: 15, Resource.stone: 10};

  static const PlayerEntity carryingTheIronAxePrice = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(resources: {Resource.wood: 5, Resource.stone: 5}, tools: {ToolKind.axe}),
  );

  static BuildingEntity get workshop =>
      BuildingEntityMock.completed(Blueprints.workshop, id: 'workshop', position: workshopPosition);

  static BuildingEntity get workshopSite =>
      BuildingEntityMock.site(Blueprints.workshop, id: 'workshop', position: workshopPosition);

  static World withWorkshop({Map<Resource, int> stock = const {}, PlayerEntity player = PlayerEntityMock.withAxe}) =>
      WorldMock.restored(player: player, buildings: [workshop])..earn(stock);
}
