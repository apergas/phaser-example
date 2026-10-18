import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/entities/hero/skill_entity.dart';

abstract final class SkillEntityMock {
  static const SkillEntity doubleStrike = SkillEntity(
    id: SkillId.doubleStrike,
    costs: [
      {Resource.gold: 60, Resource.mana: 20},
      {Resource.gold: 90, Resource.mana: 30},
      {Resource.gold: 135, Resource.mana: 45},
    ],
  );

  static const SkillEntity dodge = SkillEntity(
    id: SkillId.dodge,
    costs: [
      {Resource.gold: 90, Resource.mana: 30},
      {Resource.gold: 135, Resource.mana: 45},
      {Resource.gold: 205, Resource.mana: 70},
    ],
  );

  static const SkillEntity secondWind = SkillEntity(
    id: SkillId.secondWind,
    costs: [
      {Resource.gold: 130, Resource.mana: 45},
      {Resource.gold: 195, Resource.mana: 70},
      {Resource.gold: 295, Resource.mana: 100},
    ],
  );

  static const SkillEntity singleLevelDoubleStrike = SkillEntity(
    id: SkillId.doubleStrike,
    costs: [
      {Resource.gold: 60, Resource.mana: 20},
    ],
  );
}
