import '../geometry/position_entity.dart';
import 'activity_entity.dart';
import 'inventory_entity.dart';

class PlayerEntity {
  final PositionEntity position;
  final double speed;
  final double radius;
  final InventoryEntity inventory;
  final ActivityEntity activity;

  const PlayerEntity({
    required this.position,
    required this.speed,
    required this.radius,
    this.inventory = const InventoryEntity(),
    this.activity = const IdleActivityEntity(),
  }) : assert(speed > 0),
       assert(radius > 0);

  bool get isMoving => activity is WalkingActivityEntity;

  PlayerEntity copyWith({
    PositionEntity? position,
    double? speed,
    double? radius,
    InventoryEntity? inventory,
    ActivityEntity? activity,
  }) {
    return PlayerEntity(
      position: position ?? this.position,
      speed: speed ?? this.speed,
      radius: radius ?? this.radius,
      inventory: inventory ?? this.inventory,
      activity: activity ?? this.activity,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerEntity &&
      other.position == position &&
      other.speed == speed &&
      other.radius == radius &&
      other.inventory == inventory &&
      other.activity == activity;

  @override
  int get hashCode => Object.hash(position, speed, radius, inventory, activity);
}
