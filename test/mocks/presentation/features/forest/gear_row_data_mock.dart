import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/presentation/features/forest/models/gear_row_data.dart';

import 'gear_item_data_mock.dart';

abstract final class GearRowDataMock {
  static GearRowData get weaponNeedsForge => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.woodcutterAxe,
    next: GearItemDataMock.shortSwordNeedsForge,
  );

  static GearRowData get weaponReadyToBuy => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.woodcutterAxe,
    next: GearItemDataMock.shortSwordAvailable,
  );

  static GearRowData get weaponMaxed => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.steelSword,
  );

  static GearRowData get armorNeedsArmory => GearRowData(
    slot: GearSlot.armor,
    title: Internationalize.forestHeroSlot(slot: GearSlot.armor),
    equipped: GearItemDataMock.workClothes,
    next: GearItemDataMock.leatherArmorNeedsArmory,
  );
}
