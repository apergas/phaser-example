import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/skill_option_state.dart';
import 'package:farming/layers/domain/entities/hero/skill_option_entity.dart';
import 'package:farming/layers/domain/rules/skills.dart';

abstract final class SkillOptionEntityMock {
  static SkillOptionEntity known(SkillId id) =>
      SkillOptionEntity(skill: Skills.byId(id), state: SkillOptionState.known);

  static SkillOptionEntity make(SkillId id, SkillOptionState state, {Map<Resource, int>? missing}) {
    final skill = Skills.byId(id);
    return SkillOptionEntity(skill: skill, state: state, missing: missing ?? skill.cost);
  }

  static SkillOptionEntity get doubleStrikeAvailable =>
      make(SkillId.doubleStrike, SkillOptionState.available, missing: {});

  static SkillOptionEntity get doubleStrikeTenGoldShort =>
      make(SkillId.doubleStrike, SkillOptionState.unaffordable, missing: {Resource.gold: 10});

  static SkillOptionEntity get doubleStrikeTwentyManaShort =>
      make(SkillId.doubleStrike, SkillOptionState.unaffordable, missing: {Resource.mana: 20});

  static List<SkillOptionEntity> get newHeroWithoutTower => [
    make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
    make(SkillId.dodge, SkillOptionState.needsBuilding),
    make(SkillId.secondWind, SkillOptionState.needsBuilding),
  ];

  static List<SkillOptionEntity> get readyToLearnDoubleStrike => [
    doubleStrikeAvailable,
    make(SkillId.dodge, SkillOptionState.unaffordable, missing: {Resource.gold: 30, Resource.mana: 10}),
    make(SkillId.secondWind, SkillOptionState.unaffordable, missing: {Resource.gold: 70, Resource.mana: 25}),
  ];

  static List<SkillOptionEntity> get afterLearningDoubleStrike => [
    known(SkillId.doubleStrike),
    make(SkillId.dodge, SkillOptionState.unaffordable),
    make(SkillId.secondWind, SkillOptionState.unaffordable),
  ];
}
