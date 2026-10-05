import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';

abstract final class PlayerPoseMock {
  static WorkPose get work => WorkPose(tool: WorkTool.axe, swingProgress: 0.5);

  static WorkPose get workCopy => WorkPose(tool: WorkTool.axe, swingProgress: 0.5);

  static IdlePose get idle => IdlePose(withAxe: true);

  static WalkPose get walk => WalkPose(withAxe: true);

  static IdlePose get idleWithoutAxe => IdlePose(withAxe: false);
}
