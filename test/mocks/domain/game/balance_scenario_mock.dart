import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';

abstract final class BalanceScenarioMock {
  static const int seeds = 100;

  static const int manySeeds = 1000;

  static const int maxedSkillLevel = 3;

  static const double minWinRate = 0.6;

  static const double maxWinRate = 0.95;

  static const double maxWinRateOneStepBehind = 0.5;

  static const int maxRepeats = 3;

  static const Map<ArenaLevelId, HeroEntity> expectedHero = {
    ArenaLevelId.banditRookie: HeroEntity(),
    ArenaLevelId.wolf: HeroEntity(),
    ArenaLevelId.banditVeteran: HeroEntity(weaponTier: 1),
    ArenaLevelId.wolfPair: HeroEntity(weaponTier: 1, armorTier: 1),
    ArenaLevelId.bear: HeroEntity(weaponTier: 2, armorTier: 1),
    ArenaLevelId.banditTrio: HeroEntity(weaponTier: 2, armorTier: 2),
    ArenaLevelId.barbarian: HeroEntity(weaponTier: 2, armorTier: 2, skillLevels: {SkillId.doubleStrike: 1}),
    ArenaLevelId.wolfPack: HeroEntity(
      weaponTier: 2,
      armorTier: 2,
      skillLevels: {SkillId.doubleStrike: 1, SkillId.dodge: 1},
    ),
    ArenaLevelId.barbarianPair: HeroEntity(
      weaponTier: 3,
      armorTier: 2,
      skillLevels: {SkillId.doubleStrike: 1, SkillId.dodge: 1},
    ),
    ArenaLevelId.barbarianChief: HeroEntity(
      weaponTier: 3,
      armorTier: 3,
      skillLevels: {SkillId.doubleStrike: 1, SkillId.dodge: 1},
    ),
  };
}
