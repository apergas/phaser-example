import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';

class FighterRenderData {
  final FightSide side;
  final int index;
  final EnemyKind? enemyKind;
  final int health;
  final int maxHealth;
  final FighterPose pose;
  final double swingProgress;

  const FighterRenderData({
    required this.side,
    required this.index,
    required this.enemyKind,
    required this.health,
    required this.maxHealth,
    required this.pose,
    this.swingProgress = 0,
  });

  static String keyOf(FightSide side, int index) => '${side.name}-$index';

  String get key => keyOf(side, index);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FighterRenderData &&
          other.side == side &&
          other.index == index &&
          other.enemyKind == enemyKind &&
          other.health == health &&
          other.maxHealth == maxHealth &&
          other.pose == pose &&
          other.swingProgress == swingProgress;

  @override
  int get hashCode => Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress);
}
