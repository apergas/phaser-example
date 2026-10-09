import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';

import 'gear_row_data_mock.dart';
import 'skill_item_data_mock.dart';

abstract final class HeroPanelDataMock {
  static HeroPanelData get newHero => HeroPanelData(
    power: 31,
    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.withoutTower,
  );

  static HeroPanelData get newHeroCopy => HeroPanelData(
    power: 31,
    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.withoutTower,
  );

  static HeroPanelData get newChampion => HeroPanelData(
    power: 31,
    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.withoutTower,
    isChampion: true,
  );

  static HeroPanelData get readyToBuySword => HeroPanelData(
    power: 31,
    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponReadyToBuy, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.withoutTower,
  );

  static HeroPanelData get readyToLearnDoubleStrike => HeroPanelData(
    power: 31,
    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.readyToLearnDoubleStrike,
  );
}
