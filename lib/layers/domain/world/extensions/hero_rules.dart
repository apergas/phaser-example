import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
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

  int levelOf(SkillId skill) => skillLevels[skill] ?? 0;

  Set<SkillId> get skills => {
    for (final skill in SkillId.values)
      if (levelOf(skill) > 0) skill,
  };

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

  int get power {
    final skillPoints = SkillId.values.fold(0, (sum, skill) => sum + levelOf(skill));
    return (stats.power * (1 + skillPoints * Rules.powerPerSkill)).round();
  }

  HeroEntity withGear(GearEntity gear) => switch (gear.slot) {
    GearSlot.weapon => copyWith(weaponTier: gear.tier),
    GearSlot.armor => copyWith(armorTier: gear.tier),
  };

  HeroEntity withSkill(SkillId skill, {required int level}) {
    assert(level >= 1);
    return copyWith(skillLevels: {...skillLevels, skill: level});
  }
}
