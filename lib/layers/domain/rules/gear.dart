import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/gear_id.dart';
import '../../../core/config/constants/enum/gear_slot.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/gear/gear_entity.dart';

abstract final class Gear {
  static const List<GearEntity> all = [
    GearEntity(id: GearId.woodcutterAxe, slot: GearSlot.weapon, tier: 0, cost: {}, attackMin: 3, attackMax: 5),
    GearEntity(
      id: GearId.shortSword,
      slot: GearSlot.weapon,
      tier: 1,
      cost: {Resource.gold: 30},
      attackMin: 6,
      attackMax: 8,
    ),
    GearEntity(
      id: GearId.ironSword,
      slot: GearSlot.weapon,
      tier: 2,
      cost: {Resource.gold: 60},
      attackMin: 9,
      attackMax: 11,
    ),
    GearEntity(
      id: GearId.steelSword,
      slot: GearSlot.weapon,
      tier: 3,
      cost: {Resource.gold: 110},
      attackMin: 12,
      attackMax: 16,
    ),
    GearEntity(id: GearId.workClothes, slot: GearSlot.armor, tier: 0, cost: {}, defense: 1, health: 30),
    GearEntity(
      id: GearId.leatherArmor,
      slot: GearSlot.armor,
      tier: 1,
      cost: {Resource.gold: 40},
      defense: 3,
      health: 40,
    ),
    GearEntity(
      id: GearId.chainMail,
      slot: GearSlot.armor,
      tier: 2,
      cost: {Resource.gold: 70},
      defense: 5,
      health: 55,
    ),
    GearEntity(
      id: GearId.plateArmor,
      slot: GearSlot.armor,
      tier: 3,
      cost: {Resource.gold: 120},
      defense: 8,
      health: 75,
    ),
  ];

  static GearEntity byId(GearId id) => all.firstWhere((gear) => gear.id == id);

  static GearEntity of(GearSlot slot, int tier) =>
      find(slot, tier) ?? (throw StateError('No ${slot.name} gear at tier $tier'));

  static GearEntity? find(GearSlot slot, int tier) =>
      all.where((gear) => gear.slot == slot && gear.tier == tier).firstOrNull;

  static int maxTier(GearSlot slot) =>
      all.where((gear) => gear.slot == slot).fold(0, (max, gear) => gear.tier > max ? gear.tier : max);

  static BlueprintId workshopFor(GearSlot slot) => switch (slot) {
    GearSlot.weapon => BlueprintId.forge,
    GearSlot.armor => BlueprintId.armory,
  };
}
