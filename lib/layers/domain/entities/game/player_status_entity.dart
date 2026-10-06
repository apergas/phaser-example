import '../../../../core/config/constants/enum/player_activity.dart';
import '../geometry/position_entity.dart';
import '../player/inventory_entity.dart';

class PlayerStatusEntity {
  final PositionEntity position;
  final PlayerActivity activity;
  final PositionEntity? target;
  final double swingProgress;
  final InventoryEntity inventory;

  const PlayerStatusEntity({
    required this.position,
    required this.activity,
    this.target,
    required this.swingProgress,
    required this.inventory,
  });

  @override
  bool operator ==(Object other) =>
      other is PlayerStatusEntity &&
      other.position == position &&
      other.activity == activity &&
      other.target == target &&
      other.swingProgress == swingProgress &&
      other.inventory == inventory;

  @override
  int get hashCode => Object.hash(position, activity, target, swingProgress, inventory);
}
