import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

abstract final class PlayerEntityMock {
  static const PlayerEntity mock = PlayerEntity(position: PositionEntity(x: 100, y: 100), speed: 100, radius: 8);
}
