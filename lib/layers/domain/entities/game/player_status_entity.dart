import '../../../../core/config/constants/enum/player_activity.dart';
import '../geometry/position_entity.dart';

class PlayerStatusEntity {
  final PositionEntity position;
  final PlayerActivity activity;
  final PositionEntity? target;
  final double swingProgress;
  final int wood;
  final bool hasAxe;

  const PlayerStatusEntity({
    required this.position,
    required this.activity,
    this.target,
    required this.swingProgress,
    required this.wood,
    required this.hasAxe,
  });

  @override
  bool operator ==(Object other) =>
      other is PlayerStatusEntity &&
      other.position == position &&
      other.activity == activity &&
      other.target == target &&
      other.swingProgress == swingProgress &&
      other.wood == wood &&
      other.hasAxe == hasAxe;

  @override
  int get hashCode => Object.hash(position, activity, target, swingProgress, wood, hasAxe);
}
