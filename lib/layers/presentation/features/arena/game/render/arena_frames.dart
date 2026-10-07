import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/render/player_frames.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_sprite_names.dart';
import 'arena_render_constants.dart';

abstract final class ArenaFrames {
  static String frameName(FighterRenderData fighter, double animationSeconds) {
    final name = ArenaSpriteNames.fighter(fighter.enemyKind);
    return switch (fighter.pose) {
      FighterPose.attack => ArenaSpriteNames.slash(name, PlayerFrames.workColumn(WorkTool.axe, fighter.swingProgress)),
      FighterPose.idle || FighterPose.hurt => ArenaSpriteNames.idle(name, PlayerFrames.idleColumn(animationSeconds)),
      FighterPose.down => ArenaSpriteNames.idle(name, 0),
    };
  }

  static PositionEntity spot(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => ArenaRenderConstants.heroSpot,
      FightSide.enemy => ArenaRenderConstants.enemySpots[index],
    };
  }
}
