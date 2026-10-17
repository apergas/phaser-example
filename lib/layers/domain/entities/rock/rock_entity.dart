import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';

class RockEntity {
  final String id;
  final PositionEntity position;
  final double radius;
  final int stoneYield;
  final int hitsToBreak;
  final int hitsTaken;

  const RockEntity({
    required this.id,
    required this.position,
    required this.radius,
    required this.stoneYield,
    required this.hitsToBreak,
    this.hitsTaken = 0,
  }) : assert(radius > 0),
       assert(stoneYield >= 0),
       assert(hitsToBreak > 0),
       assert(hitsTaken >= 0 && hitsTaken <= hitsToBreak);

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: radius);

  int get hitsRemaining => hitsToBreak - hitsTaken;

  bool get isBroken => hitsRemaining == 0;

  RockEntity copyWith({
    String? id,
    PositionEntity? position,
    double? radius,
    int? stoneYield,
    int? hitsToBreak,
    int? hitsTaken,
  }) {
    return RockEntity(
      id: id ?? this.id,
      position: position ?? this.position,
      radius: radius ?? this.radius,
      stoneYield: stoneYield ?? this.stoneYield,
      hitsToBreak: hitsToBreak ?? this.hitsToBreak,
      hitsTaken: hitsTaken ?? this.hitsTaken,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RockEntity &&
      other.id == id &&
      other.position == position &&
      other.radius == radius &&
      other.stoneYield == stoneYield &&
      other.hitsToBreak == hitsToBreak &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, position, radius, stoneYield, hitsToBreak, hitsTaken);
}
