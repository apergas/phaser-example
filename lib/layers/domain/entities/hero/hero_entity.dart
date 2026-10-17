import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class HeroEntity {
  final int weaponTier;
  final int armorTier;
  final Map<SkillId, int> skillLevels;
  final Set<ArenaLevelId> clearedLevels;
  final int fightsFought;

  const HeroEntity({
    this.weaponTier = 0,
    this.armorTier = 0,
    this.skillLevels = const {},
    this.clearedLevels = const {},
    this.fightsFought = 0,
  }) : assert(weaponTier >= 0),
       assert(armorTier >= 0),
       assert(fightsFought >= 0);

  HeroEntity copyWith({
    int? weaponTier,
    int? armorTier,
    Map<SkillId, int>? skillLevels,
    Set<ArenaLevelId>? clearedLevels,
    int? fightsFought,
  }) {
    return HeroEntity(
      weaponTier: weaponTier ?? this.weaponTier,
      armorTier: armorTier ?? this.armorTier,
      skillLevels: skillLevels ?? this.skillLevels,
      clearedLevels: clearedLevels ?? this.clearedLevels,
      fightsFought: fightsFought ?? this.fightsFought,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroEntity &&
      other.weaponTier == weaponTier &&
      other.armorTier == armorTier &&
      const MapEquality<SkillId, int>().equals(other.skillLevels, skillLevels) &&
      const SetEquality<ArenaLevelId>().equals(other.clearedLevels, clearedLevels) &&
      other.fightsFought == fightsFought;

  @override
  int get hashCode => Object.hash(
    weaponTier,
    armorTier,
    const MapEquality<SkillId, int>().hash(skillLevels),
    const SetEquality<ArenaLevelId>().hash(clearedLevels),
    fightsFought,
  );
}
