import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/gear_item_data.dart';

abstract final class GearItemDataMock {
  static GearItemData get woodcutterAxe => GearItemData(
    id: GearId.woodcutterAxe,
    name: Internationalize.forestGear(id: GearId.woodcutterAxe),
    statsText: Internationalize.forestHeroWeaponStats(min: 3, max: 5),
    canBuy: false,
  );

  static GearItemData get shortSwordEquipped => GearItemData(
    id: GearId.shortSword,
    name: Internationalize.forestGear(id: GearId.shortSword),
    statsText: Internationalize.forestHeroWeaponStats(min: 6, max: 8),
    canBuy: false,
  );

  static GearItemData get shortSwordNeedsForge => _shortSword(
    reasonText: Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.forge)),
    canBuy: false,
  );

  static GearItemData get shortSwordAvailable => _shortSword(reasonText: null, canBuy: true);

  static GearItemData get shortSwordFiveGoldShort => _shortSword(
    reasonText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.gold, amount: 5),
    ),
    canBuy: false,
  );

  static GearItemData get steelSword => GearItemData(
    id: GearId.steelSword,
    name: Internationalize.forestGear(id: GearId.steelSword),
    statsText: Internationalize.forestHeroWeaponStats(min: 12, max: 16),
    canBuy: false,
  );

  static GearItemData get workClothes => GearItemData(
    id: GearId.workClothes,
    name: Internationalize.forestGear(id: GearId.workClothes),
    statsText: Internationalize.forestHeroArmorStats(defense: 1, health: 30),
    canBuy: false,
  );

  static GearItemData get leatherArmorNeedsArmory => GearItemData(
    id: GearId.leatherArmor,
    name: Internationalize.forestGear(id: GearId.leatherArmor),
    statsText: Internationalize.forestHeroArmorStats(defense: 3, health: 40),
    costText: Internationalize.forestAmount(resource: Resource.gold, amount: 40),
    reasonText: Internationalize.forestHeroNeedsBuilding(
      name: Internationalize.forestBlueprint(id: BlueprintId.armory),
    ),
    canBuy: false,
  );

  static GearItemData _shortSword({required String? reasonText, required bool canBuy}) => GearItemData(
    id: GearId.shortSword,
    name: Internationalize.forestGear(id: GearId.shortSword),
    statsText: Internationalize.forestHeroWeaponStats(min: 6, max: 8),
    costText: Internationalize.forestAmount(resource: Resource.gold, amount: 30),
    reasonText: reasonText,
    canBuy: canBuy,
  );
}
