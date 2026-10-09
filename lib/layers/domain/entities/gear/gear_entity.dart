import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/gear_id.dart';
import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../core/config/constants/enum/resource.dart';

class GearEntity {
  final GearId id;
  final GearSlot slot;
  final int tier;
  final Map<Resource, int> cost;
  final int attackMin;
  final int attackMax;
  final int defense;
  final int health;

  const GearEntity({
    required this.id,
    required this.slot,
    required this.tier,
    required this.cost,
    this.attackMin = 0,
    this.attackMax = 0,
    this.defense = 0,
    this.health = 0,
  }) : assert(tier >= 0),
       assert(attackMin >= 0),
       assert(attackMax >= attackMin),
       assert(defense >= 0),
       assert(health >= 0);

  GearEntity copyWith({
    GearId? id,
    GearSlot? slot,
    int? tier,
    Map<Resource, int>? cost,
    int? attackMin,
    int? attackMax,
    int? defense,
    int? health,
  }) {
    return GearEntity(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      tier: tier ?? this.tier,
      cost: cost ?? this.cost,
      attackMin: attackMin ?? this.attackMin,
      attackMax: attackMax ?? this.attackMax,
      defense: defense ?? this.defense,
      health: health ?? this.health,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GearEntity &&
      other.id == id &&
      other.slot == slot &&
      other.tier == tier &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      other.attackMin == attackMin &&
      other.attackMax == attackMax &&
      other.defense == defense &&
      other.health == health;

  @override
  int get hashCode =>
      Object.hash(id, slot, tier, const MapEquality<Resource, int>().hash(cost), attackMin, attackMax, defense, health);
}
