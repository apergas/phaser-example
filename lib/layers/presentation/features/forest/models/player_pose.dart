import '../../../../../core/config/constants/enum/forest/work_tool.dart';

sealed class PlayerPose {
  const PlayerPose();
}

final class IdlePose extends PlayerPose {
  final bool withAxe;

  const IdlePose({required this.withAxe});

  @override
  bool operator ==(Object other) => identical(this, other) || other is IdlePose && other.withAxe == withAxe;

  @override
  int get hashCode => Object.hash(IdlePose, withAxe);
}

final class WalkPose extends PlayerPose {
  final bool withAxe;

  const WalkPose({required this.withAxe});

  @override
  bool operator ==(Object other) => identical(this, other) || other is WalkPose && other.withAxe == withAxe;

  @override
  int get hashCode => Object.hash(WalkPose, withAxe);
}

final class WorkPose extends PlayerPose {
  final WorkTool tool;
  final double swingProgress;

  const WorkPose({required this.tool, required this.swingProgress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkPose && other.tool == tool && other.swingProgress == swingProgress;

  @override
  int get hashCode => Object.hash(WorkPose, tool, swingProgress);
}
