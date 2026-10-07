import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';

import 'gear_row_data_mock.dart';
import 'skill_item_data_mock.dart';

abstract final class HeroPanelDataMock {
  static HeroPanelData get newHero => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
  );

  static HeroPanelData get newHeroCopy => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
  );

  static HeroPanelData get readyToBuySword => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponReadyToBuy, GearRowDataMock.armorNeedsArmory],
  );

  static HeroPanelData get readyToLearnDoubleStrike => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.readyToLearnDoubleStrike,
  );
}
