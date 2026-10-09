import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';

abstract final class BalanceScenarioMock {
  static const int seeds = 100;

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
    ArenaLevelId.barbarian: HeroEntity(weaponTier: 2, armorTier: 2, skills: {SkillId.doubleStrike}),
    ArenaLevelId.wolfPack: HeroEntity(weaponTier: 2, armorTier: 2, skills: {SkillId.doubleStrike, SkillId.dodge}),
    ArenaLevelId.barbarianPair: HeroEntity(
      weaponTier: 3,
      armorTier: 2,
      skills: {SkillId.doubleStrike, SkillId.dodge},
    ),
    ArenaLevelId.barbarianChief: HeroEntity(
      weaponTier: 3,
      armorTier: 3,
      skills: {SkillId.doubleStrike, SkillId.dodge},
    ),
  };
}
