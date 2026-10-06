import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/entities/game/player_status_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../player/inventory_entity_mock.dart';

abstract final class PlayerStatusEntityMock {
  static const PlayerStatusEntity mock = PlayerStatusEntity(
    position: PositionEntity(x: 100, y: 100),
    activity: PlayerActivity.idle,
    swingProgress: 0,
    inventory: InventoryEntityMock.mock,
  );

  static const PlayerStatusEntity withTarget = PlayerStatusEntity(
    position: PositionEntity(x: 100, y: 100),
    activity: PlayerActivity.idle,
    target: PositionEntity(x: 1, y: 1),
    swingProgress: 0,
    inventory: InventoryEntityMock.mock,
  );

  static PlayerStatusEntity make() {
    return PlayerStatusEntity(
      position: const PositionEntity(x: 100, y: 100),
      activity: PlayerActivity.idle,
      swingProgress: 0,
      inventory: InventoryEntityMock.mock,
    );
  }
}
