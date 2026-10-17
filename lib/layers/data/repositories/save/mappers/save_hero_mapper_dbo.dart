import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/hero/hero_entity.dart';
import '../../../../domain/rules/gear.dart';
import '../../../../domain/rules/skills.dart';
import '../../../datasources/save/local/dbo/save_hero_dbo.dart';

@Injectable()
class SaveHeroMapperDBO {
  SaveHeroDBO toDBO(HeroEntity hero) {
    return SaveHeroDBO(
      weaponTier: hero.weaponTier,
      armorTier: hero.armorTier,
      skillLevels: {for (final MapEntry(key: id, value: level) in hero.skillLevels.entries) id.name: level},
      clearedLevels: [for (final level in hero.clearedLevels) level.name],
      fightsFought: hero.fightsFought,
    );
  }

  HeroEntity toEntity(SaveHeroDBO? dbo) {
    if (dbo == null) return const HeroEntity();
    final skillLevels = <SkillId, int>{};
    for (final MapEntry(key: name, value: level) in (dbo.skillLevels ?? const <String, int>{}).entries) {
      final id = SkillId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'hero: unknown skill "$name"'));
      final maxLevel = Skills.byId(id).maxLevel;
      if (level < 1 || level > maxLevel) throw InvalidSaveException(data: 'hero: ${id.name} level $level of $maxLevel');
      skillLevels[id] = level;
    }
    final fightsFought = dbo.fightsFought ?? 0;
    if (fightsFought < 0) throw InvalidSaveException(data: 'hero: $fightsFought fights');
    return HeroEntity(
      weaponTier: _tier(dbo.weaponTier, GearSlot.weapon),
      armorTier: _tier(dbo.armorTier, GearSlot.armor),
      skillLevels: skillLevels,
      clearedLevels: {
        for (final name in dbo.clearedLevels ?? const <String>[])
          ArenaLevelId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'hero: unknown level "$name"')),
      },
      fightsFought: fightsFought,
    );
  }

  int _tier(int? tier, GearSlot slot) {
    final value = tier ?? 0;
    if (value < 0 || value > Gear.maxTier(slot)) throw InvalidSaveException(data: 'hero: ${slot.name} tier $value');
    return value;
  }
}
