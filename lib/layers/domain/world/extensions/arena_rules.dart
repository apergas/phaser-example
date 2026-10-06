import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import '../../entities/combat/arena_level_entity.dart';
import '../../entities/combat/fight_log_entity.dart';
import '../../entities/hero/hero_entity.dart';
import '../../rules/arena_levels.dart';
import '../../rules/rules.dart';

extension ArenaRules on HeroEntity {
  bool isUnlocked(ArenaLevelEntity level) {
    final index = ArenaLevels.all.indexWhere((candidate) => candidate.id == level.id);
    if (index < 0) return false;
    return index == 0 || hasCleared(ArenaLevels.all[index - 1].id);
  }

  bool hasCleared(ArenaLevelId id) => clearedLevels.contains(id);

  Map<Resource, int> rewardFor(ArenaLevelEntity level) {
    if (!hasCleared(level.id)) return level.reward;
    return {
      for (final MapEntry(key: resource, value: amount) in level.reward.entries)
        if (amount ~/ Rules.repeatRewardDivisor > 0) resource: amount ~/ Rules.repeatRewardDivisor,
    };
  }

  HeroEntity afterFight(FightLogEntity log) => copyWith(
    clearedLevels: log.isVictory ? {...clearedLevels, log.levelId} : clearedLevels,
    fightsFought: fightsFought + 1,
  );
}
