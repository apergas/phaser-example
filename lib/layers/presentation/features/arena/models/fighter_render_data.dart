import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';

class FighterRenderData {
  final FightSide side;
  final int index;
  final EnemyKind? enemyKind;
  final int health;
  final int maxHealth;
  final FighterPose pose;
  final double swingProgress;
  final int targetIndex;
  final bool isTargeted;
  final GearId? weapon;

  const FighterRenderData({
    required this.side,
    required this.index,
    required this.enemyKind,
    required this.health,
    required this.maxHealth,
    required this.pose,
    this.swingProgress = 0,
    this.targetIndex = 0,
    this.isTargeted = false,
    this.weapon,
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
          other.swingProgress == swingProgress &&
          other.targetIndex == targetIndex &&
          other.isTargeted == isTargeted &&
          other.weapon == weapon;

  @override
  int get hashCode =>
      Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex, isTargeted, weapon);
}
