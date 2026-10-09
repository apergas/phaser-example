import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/render/easing.dart';
import '../../../forest/game/render/player_frames.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_sprite_names.dart';
import 'arena_render_constants.dart';

abstract final class ArenaFrames {
  static String frameName(FighterRenderData fighter, double animationSeconds) {
    final name = ArenaSpriteNames.fighter(fighter.enemyKind, weapon: fighter.weapon);
    final leap = ArenaRenderConstants.leapSequence(fighter.enemyKind);
    return switch (fighter.pose) {
      FighterPose.attack when leap != null => ArenaSpriteNames.attack(
        name,
        sequenceColumn(leap, fighter.swingProgress),
      ),
      FighterPose.attack when isWalking(fighter.swingProgress) => ArenaSpriteNames.walk(
        name,
        PlayerFrames.walkColumn(animationSeconds),
      ),
      FighterPose.attack => ArenaSpriteNames.slash(
        name,
        PlayerFrames.workColumn(WorkTool.axe, strikeProgress(fighter.swingProgress)),
      ),
      FighterPose.idle || FighterPose.hurt => ArenaSpriteNames.idle(name, PlayerFrames.idleColumn(animationSeconds)),
      FighterPose.down when leap != null => ArenaSpriteNames.down(name),
      FighterPose.down => ArenaSpriteNames.idle(name, 0),
    };
  }

  static PositionEntity spot(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => ArenaRenderConstants.heroSpot,
      FightSide.enemy => ArenaRenderConstants.enemySpots[index],
    };
  }

  static FightSide opposite(FightSide side) {
    return switch (side) {
      FightSide.hero => FightSide.enemy,
      FightSide.enemy => FightSide.hero,
    };
  }

  static bool isBeast(EnemyKind? kind) => ArenaRenderConstants.leapSequence(kind) != null;

  static int sequenceColumn(List<int> sequence, double progress) {
    final step = math.min(sequence.length - 1, (progress * sequence.length).floor());
    return sequence[math.max(0, step)];
  }

  static bool isLeaping(FighterRenderData fighter) => fighter.pose == FighterPose.attack && isBeast(fighter.enemyKind);

  static bool isWalking(double progress) =>
      progress < ArenaRenderConstants.approachOutShare || progress > ArenaRenderConstants.approachBackShare;

  static double strikeProgress(double progress) {
    const out = ArenaRenderConstants.approachOutShare;
    const back = ArenaRenderConstants.approachBackShare;
    return ((progress - out) / (back - out)).clamp(0, 1).toDouble();
  }

  static double leapReach(double progress) =>
      _reach(progress, ArenaRenderConstants.leapOutShare, ArenaRenderConstants.leapBackShare);

  static double approachReach(double progress) =>
      _reach(progress, ArenaRenderConstants.approachOutShare, ArenaRenderConstants.approachBackShare);

  static double _reach(double progress, double out, double back) {
    if (progress <= 0) return 0;
    if (progress < out) return Easing.sineOut(progress / out);
    if (progress <= back) return 1;
    return 1 - Easing.sineInOut(math.min(1, (progress - back) / (1 - back)));
  }

  static double leapLift(double progress) {
    const out = ArenaRenderConstants.leapOutShare;
    const back = ArenaRenderConstants.leapBackShare;
    if (progress <= 0 || progress >= 1 || (progress >= out && progress <= back)) return 0;
    final hop = progress < out ? progress / out : (progress - back) / (1 - back);
    return ArenaRenderConstants.leapHeight * math.sin(math.pi * hop);
  }

  static PositionEntity groundSpot(FighterRenderData fighter) {
    final home = spot(fighter.side, fighter.index);
    if (fighter.pose != FighterPose.attack) return home;
    final leaping = isBeast(fighter.enemyKind);
    final gap = leaping ? ArenaRenderConstants.leapGap : ArenaRenderConstants.approachGap;
    final reach = leaping ? leapReach(fighter.swingProgress) : approachReach(fighter.swingProgress);
    final target = spot(opposite(fighter.side), fighter.targetIndex);
    final dx = target.x - home.x;
    final dy = target.y - home.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= gap) return home;
    final travel = (distance - gap) / distance * reach;
    return PositionEntity(x: home.x + dx * travel, y: home.y + dy * travel);
  }

  static double lift(FighterRenderData fighter) => isLeaping(fighter) ? leapLift(fighter.swingProgress) : 0;
}
