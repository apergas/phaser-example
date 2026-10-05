import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import 'player_pose.dart';

class PlayerRenderData {
  final PositionEntity position;
  final Facing facing;
  final PlayerPose pose;

  const PlayerRenderData({required this.position, required this.facing, required this.pose});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerRenderData && other.position == position && other.facing == facing && other.pose == pose;

  @override
  int get hashCode => Object.hash(position, facing, pose);
}
