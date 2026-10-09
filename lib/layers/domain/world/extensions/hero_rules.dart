import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../entities/gear/gear_entity.dart';
import '../../entities/hero/combat_stats_entity.dart';
import '../../entities/hero/hero_entity.dart';
import '../../rules/gear.dart';
import '../../rules/rules.dart';

extension HeroRules on HeroEntity {
  int tierOf(GearSlot slot) => switch (slot) {
    GearSlot.weapon => weaponTier,
    GearSlot.armor => armorTier,
  };

  GearEntity equipped(GearSlot slot) => Gear.of(slot, tierOf(slot));

  GearEntity? nextGear(GearSlot slot) => Gear.find(slot, tierOf(slot) + 1);

  CombatStatsEntity get stats {
    final weapon = equipped(GearSlot.weapon);
    final armor = equipped(GearSlot.armor);
    return CombatStatsEntity(
      attackMin: weapon.attackMin + armor.attackMin,
      attackMax: weapon.attackMax + armor.attackMax,
      defense: weapon.defense + armor.defense,
      health: weapon.health + armor.health,
    );
  }

  int get power => (stats.power * (1 + skills.length * Rules.powerPerSkill)).round();

  HeroEntity withGear(GearEntity gear) => switch (gear.slot) {
    GearSlot.weapon => copyWith(weaponTier: gear.tier),
    GearSlot.armor => copyWith(armorTier: gear.tier),
  };
}
