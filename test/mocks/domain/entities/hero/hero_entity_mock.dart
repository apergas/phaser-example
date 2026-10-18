import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';

abstract final class HeroEntityMock {
  static const HeroEntity mock = HeroEntity();

  static const HeroEntity withShortSwordAndLeather = HeroEntity(weaponTier: 1, armorTier: 1);

  static const HeroEntity fullyGeared = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.secondWind: 1, SkillId.dodge: 1},
  );

  static const HeroEntity withTwoSkills = HeroEntity(
    weaponTier: 1,
    armorTier: 1,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.dodge: 1},
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

  static const HeroEntity dodgerAfterOneFight = HeroEntity(skillLevels: {SkillId.dodge: 1}, fightsFought: 1);

  static const HeroEntity veteranWithSecondWind = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    skillLevels: {SkillId.secondWind: 1},
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

  static const HeroEntity banditTrioCleared = HeroEntity(clearedLevels: {ArenaLevelId.banditTrio});

  static const HeroEntity packHunter = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    clearedLevels: {ArenaLevelId.barbarian},
  );

  static const HeroEntity withDoubleStrike = HeroEntity(skillLevels: {SkillId.doubleStrike: 1});

  static const HeroEntity chiefChallenger = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.secondWind: 1, SkillId.dodge: 1},
    clearedLevels: {ArenaLevelId.barbarianPair},
    fightsFought: 9,
  );

  static const HeroEntity newChampion = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.secondWind: 1, SkillId.dodge: 1},
    clearedLevels: {ArenaLevelId.barbarianPair, ArenaLevelId.barbarianChief},
    fightsFought: 10,
  );

  static const HeroEntity champion = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.secondWind: 1, SkillId.dodge: 1},
    clearedLevels: {ArenaLevelId.barbarianPair, ArenaLevelId.barbarianChief},
    fightsFought: 13,
  );

  static const HeroEntity championWithEveryQuestDone = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.secondWind: 1, SkillId.dodge: 1},
    clearedLevels: {
      ArenaLevelId.banditRookie,
      ArenaLevelId.banditVeteran,
      ArenaLevelId.banditTrio,
      ArenaLevelId.barbarian,
      ArenaLevelId.barbarianPair,
      ArenaLevelId.barbarianChief,
    },
    fightsFought: 12,
  );

  static const HeroEntity withDoubleStrikeAtLevelTwo = HeroEntity(skillLevels: {SkillId.doubleStrike: 2});

  static const HeroEntity withDoubleStrikeAtLevelThree = HeroEntity(skillLevels: {SkillId.doubleStrike: 3});

  static const HeroEntity championWithMaxedSkills = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 3, SkillId.secondWind: 3, SkillId.dodge: 3},
  );

  static const HeroEntity bronzeAndChain = HeroEntity(weaponTier: 2, armorTier: 2);

  static const HeroEntity steelAndPlate = HeroEntity(weaponTier: 3, armorTier: 3);

  static const HeroEntity bronzeAndLeatherWithEverySkillAtLevelTwo = HeroEntity(
    weaponTier: 2,
    armorTier: 1,
    skillLevels: {SkillId.doubleStrike: 2, SkillId.secondWind: 2, SkillId.dodge: 2},
  );

  static const HeroEntity steelAndPlateWithEverySkillAtLevelTwo = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 2, SkillId.secondWind: 2, SkillId.dodge: 2},
  );

  static const HeroEntity bronzeAndLeatherWithEverySkillAtLevelThree = HeroEntity(
    weaponTier: 2,
    armorTier: 1,
    skillLevels: {SkillId.doubleStrike: 3, SkillId.secondWind: 3, SkillId.dodge: 3},
  );

  static const HeroEntity steelAndPlateWithEverySkillAtLevelThree = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 3, SkillId.secondWind: 3, SkillId.dodge: 3},
  );

  static const HeroEntity barbarianChallenger = HeroEntity(
    weaponTier: 2,
    armorTier: 2,
    skillLevels: {SkillId.doubleStrike: 1},
    clearedLevels: {ArenaLevelId.banditTrio},
    fightsFought: 25,
  );

  static const HeroEntity expectedChiefChallenger = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skillLevels: {SkillId.doubleStrike: 1, SkillId.dodge: 1},
    clearedLevels: {ArenaLevelId.barbarianPair},
    fightsFought: 1,
  );

  static const HeroEntity inChainMail = HeroEntity(armorTier: 2);
}
