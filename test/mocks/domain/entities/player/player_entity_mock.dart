import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/entities/player/intent_entity.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';

abstract final class PlayerEntityMock {
  static const PlayerEntity mock = PlayerEntity(position: PositionEntity(x: 100, y: 100), speed: 100, radius: 8);

  static const PlayerEntity withAxe = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(tools: {ToolKind.axe}),
  );

  static const PlayerEntity withAxeBelowTree = PlayerEntity(
    position: PositionEntity(x: 100, y: 300),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(tools: {ToolKind.axe}),
  );

  static const PlayerEntity withFifteenWood = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(resources: {Resource.wood: 15}),
  );

  static const PlayerEntity withSeventeenWood = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(resources: {Resource.wood: 17}),
  );

  static const PlayerEntity centered = PlayerEntity(position: PositionEntity(x: 50, y: 50), speed: 100, radius: 8);

  static PlayerEntity make({double speed = 100, double radius = 8}) =>
      PlayerEntity(position: const PositionEntity(x: 0, y: 0), speed: speed, radius: radius);

  static const PlayerEntity onTheStump = PlayerEntity(position: PositionEntity(x: 200, y: 119), speed: 100, radius: 8);

  static const PlayerEntity besideTheStump = PlayerEntity(
    position: PositionEntity(x: 200, y: 122),
    speed: 100,
    radius: 8,
  );

  static const PlayerEntity aboutToHitTheTree = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(tools: {ToolKind.axe}),
    activity: WorkingActivityEntity(intent: ChopIntentEntity(treeId: 'tree-1'), elapsedMs: 749),
  );

  static const PlayerEntity withPickaxe = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(tools: {ToolKind.axe, ToolKind.pickaxe}),
  );
}
