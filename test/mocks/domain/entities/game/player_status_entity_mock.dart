import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/entities/game/player_status_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

abstract final class PlayerStatusEntityMock {
  static const PlayerStatusEntity mock = PlayerStatusEntity(
    position: PositionEntity(x: 100, y: 100),
    activity: PlayerActivity.idle,
    swingProgress: 0,
    wood: 0,
    hasAxe: false,
  );
}
