import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_render_data.dart';

abstract final class PlayerRenderDataMock {
  static PlayerRenderData get chopping => PlayerRenderData(
    position: const PositionEntity(x: 0, y: 0),
    facing: Facing.left,
    pose: const WorkPose(tool: WorkTool.axe, swingProgress: 0.3),
  );

  static PlayerRenderData get walkingWithAxe => PlayerRenderData(
    position: const PositionEntity(x: 0, y: 0),
    facing: Facing.right,
    pose: const WalkPose(withAxe: true),
  );
}
