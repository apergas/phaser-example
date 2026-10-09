import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/arena/models/fighter_render_data.dart';

abstract final class FighterRenderDataMock {
  static const FighterRenderData heroIdle = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
    weapon: GearId.woodcutterAxe,
  );

  static const FighterRenderData heroWithSteelSwordIdle = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
    weapon: GearId.steelSword,
  );

  static const FighterRenderData rookieBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 20,
    maxHealth: 20,
    pose: FighterPose.idle,
    isTargeted: true,
  );

  static const FighterRenderData veteranBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.banditVeteran,
    health: 36,
    maxHealth: 36,
    pose: FighterPose.idle,
    isTargeted: true,
  );

  static const FighterRenderData wolfIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 20,
    maxHealth: 20,
    pose: FighterPose.idle,
    isTargeted: true,
  );

  static const FighterRenderData rookieBanditHurt = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 16,
    maxHealth: 20,
    pose: FighterPose.hurt,
    isTargeted: true,
  );

  static const FighterRenderData rookieBanditAfterFirstBlow = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 17,
    maxHealth: 20,
    pose: FighterPose.hurt,
    isTargeted: true,
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
    weapon: GearId.woodcutterAxe,
  );

  static FighterRenderData heroSwinging(double swingProgress) => FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
    weapon: GearId.woodcutterAxe,
  );

  static const FighterRenderData chiefIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.barbarianChief,
    health: 70,
    maxHealth: 70,
    pose: FighterPose.idle,
  );

  static FighterRenderData wolfLeaping(double swingProgress) => FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 18,
    maxHealth: 20,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
    isTargeted: true,
  );

  static FighterRenderData bearLeaping(double swingProgress) => FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bear,
    health: 40,
    maxHealth: 40,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
  );

  static const FighterRenderData wolfDown = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 0,
    maxHealth: 22,
    pose: FighterPose.down,
  );
}
