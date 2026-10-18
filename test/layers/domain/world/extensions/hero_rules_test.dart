import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/gear_id.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/gear_slot.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/rules/gear.dart';
import 'package:farming/layers/domain/world/extensions/hero_rules.dart';

import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/balance_scenario_mock.dart';

void main() {
  test('testWhenTheHeroHasBasicGearThenStatsAreTheBaseStats', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroBase);
    expect(hero.power, 31);
  });

  test('testWhenTheHeroHasShortSwordAndLeatherThenStatsAddBothPieces', () {
    // given
    const hero = HeroEntityMock.withShortSwordAndLeather;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroWithShortSwordAndLeather);
  });

  test('testWhenTheHeroKnowsTwoSkillsThenPowerGrowsTwentyPercent', () {
    // given
    const hero = HeroEntityMock.withTwoSkills;

    // when
    final power = hero.power;

    // then
    expect(power, 64);
  });

  test('testWhenTheHeroIsFullyGearedThenThereIsNoNextGear', () {
    // given
    const hero = HeroEntityMock.fullyGeared;

    // when
    final next = (hero.nextGear(GearSlot.weapon), hero.nextGear(GearSlot.armor));

    // then
    expect(next, (null, null));
    expect(hero.stats, CombatStatsEntityMock.heroFullyGeared);
    expect(hero.power, 144);
  });

  test('testWhenEquippingGearThenOnlyItsSlotTierChanges', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final equipped = hero.withGear(Gear.byId(GearId.ironSword));

    // then
    expect((equipped.tierOf(GearSlot.weapon), equipped.tierOf(GearSlot.armor)), (2, 0));
    expect(equipped.equipped(GearSlot.weapon).id, GearId.ironSword);
  });

  test('testWhenTheHeroHasNotLearnedASkillThenItsLevelIsZero', () {
    // given
    const hero = HeroEntityMock.withDoubleStrikeAtLevelTwo;

    // when
    final levels = SkillId.values.map(hero.levelOf).toList();

    // then
    expect(levels, [2, 0, 0]);
  });

  test('testWhenListingTheSkillsThenOnlyLearnedOnesAppearInSkillIdOrder', () {
    // given
    const hero = HeroEntityMock.championWithMaxedSkills;

    // when
    final skills = hero.skills.toList();
    final none = HeroEntityMock.withShortSword.copyWith(skillLevels: {SkillId.dodge: 0}).skills;

    // then
    expect(skills, SkillId.values);
    expect(none, isEmpty);
  });

  test('testWhenLearningOrUpgradingASkillThenOnlyThatSkillLevelChanges', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final learned = hero.withSkill(SkillId.doubleStrike, level: 1);
    final upgraded = learned.withSkill(SkillId.doubleStrike, level: 2);

    // then
    expect(learned, HeroEntityMock.withDoubleStrike);
    expect(upgraded, HeroEntityMock.withDoubleStrikeAtLevelTwo);
  });

  test('testWhenTheLevelIsZeroOrAboveTheMaxThenWithSkillAsserts', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    void zero() => hero.withSkill(SkillId.dodge, level: 0);
    void four() => hero.withSkill(SkillId.dodge, level: 4);

    // then
    expect(zero, throwsA(isA<AssertionError>()));
    expect(four, throwsA(isA<AssertionError>()));
  });

  test('testWhenEverySkillIsAtLevelTwoOrThreeThenPowerCountsEachLevel', () {
    // given
    const heroes = [
      HeroEntityMock.bronzeAndLeatherWithEverySkillAtLevelTwo,
      HeroEntityMock.steelAndPlateWithEverySkillAtLevelTwo,
      HeroEntityMock.bronzeAndLeatherWithEverySkillAtLevelThree,
      HeroEntityMock.steelAndPlateWithEverySkillAtLevelThree,
    ];

    // when
    final powers = heroes.map((hero) => hero.power).toList();

    // then
    expect(powers, [99, 178, 118, 211]);
  });

  test('testWhenTheChiefChallengerUpgradesItsSkillsThenItsPowerGrows', () {
    // given
    final hero = BalanceScenarioMock.expectedHero[ArenaLevelId.barbarianChief]!;

    // when
    final powers = [
      for (var level = 1; level <= 3; level++)
        hero.copyWith(skillLevels: {for (final skill in hero.skills) skill: level}).power,
    ];

    // then
    expect(powers, [133, 155, 178]);
  });
}
