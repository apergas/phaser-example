import '../../../../core/config/constants/enum/tree_kind.dart';
import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';

class TreeEntity {
  final String id;
  final TreeKind kind;
  final PositionEntity position;
  final double trunkRadius;
  final int woodYield;
  final int hitsToFell;
  final int hitsTaken;

  const TreeEntity({
    required this.id,
    required this.kind,
    required this.position,
    required this.trunkRadius,
    required this.woodYield,
    required this.hitsToFell,
    this.hitsTaken = 0,
  }) : assert(woodYield >= 0),
       assert(hitsToFell > 0);

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: trunkRadius);

  int get hitsRemaining => hitsToFell - hitsTaken;

  bool get isFelled => hitsRemaining == 0;

  TreeEntity copyWith({
    String? id,
    TreeKind? kind,
    PositionEntity? position,
    double? trunkRadius,
    int? woodYield,
    int? hitsToFell,
    int? hitsTaken,
  }) {
    return TreeEntity(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      position: position ?? this.position,
      trunkRadius: trunkRadius ?? this.trunkRadius,
      woodYield: woodYield ?? this.woodYield,
      hitsToFell: hitsToFell ?? this.hitsToFell,
      hitsTaken: hitsTaken ?? this.hitsTaken,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TreeEntity &&
      other.id == id &&
      other.kind == kind &&
      other.position == position &&
      other.trunkRadius == trunkRadius &&
      other.woodYield == woodYield &&
      other.hitsToFell == hitsToFell &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, kind, position, trunkRadius, woodYield, hitsToFell, hitsTaken);
}
