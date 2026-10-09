import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/skill_id.dart';
import '../entities/hero/skill_entity.dart';

abstract final class Skills {
  static const BlueprintId building = BlueprintId.mageTower;

  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});

  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});

  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});

  static const List<SkillEntity> all = [doubleStrike, dodge, secondWind];

  static SkillEntity byId(SkillId id) => all.firstWhere((skill) => skill.id == id);
}
