import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/presentation/features/arena/models/fighter_render_data.dart';

abstract final class FighterRenderDataMock {
  static const FighterRenderData heroIdle = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static const FighterRenderData rookieBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 20,
    maxHealth: 20,
    pose: FighterPose.idle,
  );

  static const FighterRenderData veteranBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static const FighterRenderData wolfIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 22,
    maxHealth: 22,
    pose: FighterPose.idle,
  );

  static const FighterRenderData rookieBanditHurt = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 16,
    maxHealth: 20,
    pose: FighterPose.hurt,
  );

  static const FighterRenderData rookieBanditDown = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 0,
    maxHealth: 20,
    pose: FighterPose.down,
  );

  static const FighterRenderData heroAfterBeatingTheRookie = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 22,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static FighterRenderData heroSwinging(double swingProgress) => FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
  );

  static const FighterRenderData chiefIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.barbarianChief,
    health: 70,
    maxHealth: 70,
    pose: FighterPose.idle,
  );
}
