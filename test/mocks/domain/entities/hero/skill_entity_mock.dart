import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/entities/hero/skill_entity.dart';

abstract final class SkillEntityMock {
  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});

  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});

  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});
}
