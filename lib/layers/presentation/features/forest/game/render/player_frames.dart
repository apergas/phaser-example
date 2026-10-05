import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import '../../models/player_pose.dart';
import '../../models/player_render_data.dart';
import 'player_frame.dart';

abstract final class PlayerFrames {
  static int row(Facing facing) {
    return switch (facing) {
      Facing.up => RenderConstants.rowUp,
      Facing.left => RenderConstants.rowLeft,
      Facing.down => RenderConstants.rowDown,
      Facing.right => RenderConstants.rowRight,
    };
  }

  static int walkColumn(double seconds) {
    final steps = RenderConstants.walkLastStep - RenderConstants.walkFirstStep + 1;
    return RenderConstants.walkFirstStep + (seconds * RenderConstants.walkFps).floor() % steps;
  }

  static int idleColumn(double seconds) => (seconds * RenderConstants.idleFps).floor() % RenderConstants.idleColumns;

  static int workColumn(WorkTool tool, double swingProgress) {
    final sequence = tool == WorkTool.axe ? RenderConstants.chopSequence : RenderConstants.hammerSequence;
    final step = math.min(sequence.length - 1, (swingProgress * sequence.length).floor());
    return sequence[math.max(0, step)];
  }

  static PlayerSheet sheet(PlayerPose pose) {
    return switch (pose) {
      IdlePose(:final withAxe) => withAxe ? PlayerSheet.idleAxe : PlayerSheet.idle,
      WalkPose(:final withAxe) => withAxe ? PlayerSheet.walkAxe : PlayerSheet.walk,
      WorkPose(:final tool) => tool == WorkTool.axe ? PlayerSheet.chop : PlayerSheet.hammer,
    };
  }

  static String animationKey(PlayerRenderData player) => '${sheet(player.pose).name}-${player.facing.name}';

  static PlayerFrame frame(PlayerRenderData player, double animationSeconds) {
    final pose = player.pose;
    final playerRow = row(player.facing);
    return switch (pose) {
      WorkPose(:final tool, :final swingProgress) => PlayerFrame(
        sheet: sheet(pose),
        column: workColumn(tool, swingProgress),
        row: playerRow,
        cellSize: RenderConstants.workFrameSize,
        anchorY: RenderConstants.workAnchorY,
      ),
      WalkPose() => PlayerFrame(
        sheet: sheet(pose),
        column: walkColumn(animationSeconds),
        row: playerRow,
        cellSize: RenderConstants.characterFrameSize,
        anchorY: RenderConstants.characterAnchorY,
      ),
      IdlePose() => PlayerFrame(
        sheet: sheet(pose),
        column: idleColumn(animationSeconds),
        row: playerRow,
        cellSize: RenderConstants.characterFrameSize,
        anchorY: RenderConstants.characterAnchorY,
      ),
    };
  }
}
