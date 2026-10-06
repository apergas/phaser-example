import '../../../core/config/constants/enum/gear_id.dart';
import '../../../core/config/constants/enum/gear_slot.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/gear/gear_entity.dart';

abstract final class Gear {
  static const List<GearEntity> all = [
    GearEntity(id: GearId.woodcutterAxe, slot: GearSlot.weapon, tier: 0, cost: {}, attack: 4),
    GearEntity(
      id: GearId.shortSword,
      slot: GearSlot.weapon,
      tier: 1,
      cost: {Resource.wood: 20, Resource.gold: 10},
      attack: 7,
    ),
    GearEntity(
      id: GearId.ironSword,
      slot: GearSlot.weapon,
      tier: 2,
      cost: {Resource.wood: 30, Resource.gold: 40},
      attack: 10,
    ),
    GearEntity(
      id: GearId.steelSword,
      slot: GearSlot.weapon,
      tier: 3,
      cost: {Resource.wood: 40, Resource.gold: 120},
      attack: 14,
    ),
    GearEntity(id: GearId.workClothes, slot: GearSlot.armor, tier: 0, cost: {}, defense: 1, health: 30),
    GearEntity(
      id: GearId.leatherArmor,
      slot: GearSlot.armor,
      tier: 1,
      cost: {Resource.wood: 15, Resource.gold: 15},
      defense: 3,
      health: 40,
    ),
    GearEntity(
      id: GearId.chainMail,
      slot: GearSlot.armor,
      tier: 2,
      cost: {Resource.wood: 30, Resource.gold: 50},
      defense: 5,
      health: 55,
    ),
    GearEntity(
      id: GearId.plateArmor,
      slot: GearSlot.armor,
      tier: 3,
      cost: {Resource.wood: 40, Resource.gold: 150},
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
}
