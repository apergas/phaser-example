import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

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
    inventory: InventoryEntity(wood: 15),
  );

  static const PlayerEntity withSeventeenWood = PlayerEntity(
    position: PositionEntity(x: 100, y: 100),
    speed: 100,
    radius: 8,
    inventory: InventoryEntity(wood: 17),
  );

  static const PlayerEntity centered = PlayerEntity(position: PositionEntity(x: 50, y: 50), speed: 100, radius: 8);

  static PlayerEntity make({double speed = 100, double radius = 8}) =>
      PlayerEntity(position: const PositionEntity(x: 0, y: 0), speed: speed, radius: radius);
}
