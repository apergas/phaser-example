import 'package:farming/layers/data/datasources/save/local/dbo/save_hero_dbo.dart';

abstract final class SaveHeroDBOMock {
  static const SaveHeroDBO mock = SaveHeroDBO(
    weaponTier: 2,
    armorTier: 1,
    skillLevels: {'doubleStrike': 2, 'dodge': 1},
    clearedLevels: ['banditRookie', 'wolf'],
    fightsFought: 5,
  );
  static const SaveHeroDBO empty = SaveHeroDBO();
  static const SaveHeroDBO withMaxTiers = SaveHeroDBO(weaponTier: 3, armorTier: 3);
  static const SaveHeroDBO withMaxSkillLevel = SaveHeroDBO(skillLevels: {'secondWind': 3});
  static const SaveHeroDBO weaponTierTooHigh = SaveHeroDBO(weaponTier: 4);
  static const SaveHeroDBO armorTierTooHigh = SaveHeroDBO(armorTier: 4);
  static const SaveHeroDBO weaponTierNegative = SaveHeroDBO(weaponTier: -1);
  static const SaveHeroDBO armorTierNegative = SaveHeroDBO(armorTier: -1);
  static const SaveHeroDBO unknownSkill = SaveHeroDBO(skillLevels: {'fireball': 1});
  static const SaveHeroDBO skillLevelZero = SaveHeroDBO(skillLevels: {'dodge': 0});
  static const SaveHeroDBO skillLevelTooHigh = SaveHeroDBO(skillLevels: {'dodge': 4});
  static const SaveHeroDBO unknownLevel = SaveHeroDBO(clearedLevels: ['dragon']);
  static const SaveHeroDBO negativeFights = SaveHeroDBO(fightsFought: -1);
  static const Map<String, dynamic> wrongTypes = {'weaponTier': 'iron'};
  static const Map<String, dynamic> wrongSkillLevelType = {
    'skillLevels': {'dodge': 1.5},
  };
  static const Map<String, dynamic> wrongClearedLevelsType = {'clearedLevels': 'wolf'};
}
