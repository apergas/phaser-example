import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';

abstract final class HeroEntityMock {
  static const HeroEntity mock = HeroEntity();

  static const HeroEntity withShortSwordAndLeather = HeroEntity(weaponTier: 1, armorTier: 1);

  static const HeroEntity fullyGeared = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skills: {SkillId.doubleStrike, SkillId.secondWind, SkillId.dodge},
  );

  static const HeroEntity withTwoSkills = HeroEntity(
    weaponTier: 1,
    armorTier: 1,
    skills: {SkillId.doubleStrike, SkillId.dodge},
  );

  static const HeroEntity veteran = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie},
    fightsFought: 3,
  );

  static const HeroEntity afterFirstVictory = HeroEntity(clearedLevels: {ArenaLevelId.banditRookie}, fightsFought: 1);

  static const HeroEntity afterFirstDefeat = HeroEntity(fightsFought: 1);

  static const HeroEntity veteranAfterAnotherFight = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie},
    fightsFought: 4,
  );

  static const HeroEntity withShortSword = HeroEntity(weaponTier: 1);

  static const HeroEntity dodgerAfterOneFight = HeroEntity(skills: {SkillId.dodge}, fightsFought: 1);

  static const HeroEntity veteranWithSecondWind = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    skills: {SkillId.secondWind},
  );

  static const HeroEntity wolfHunter = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    fightsFought: 3,
  );

  static const HeroEntity wolfHunterAfterAnotherFight = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    fightsFought: 4,
  );

  static const HeroEntity beforeTheBeasts = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.banditVeteran},
    fightsFought: 2,
  );
}
