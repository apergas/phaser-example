import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/rock/rock_entity.dart';

abstract final class RockEntityMock {
  static const RockEntity intact = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 300, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
  );

  static const RockEntity almostBroken = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 300, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
    hitsTaken: 7,
  );

  static const RockEntity broken = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 300, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
    hitsTaken: 8,
  );

  static const RockEntity onceHit = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 300, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
    hitsTaken: 1,
  );

  static const RockEntity nextToStump = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 233, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
  );

  static const RockEntity nearStump = RockEntity(
    id: 'rock-1',
    position: PositionEntity(x: 235, y: 100),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 8,
  );
}
