import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/gear_slot.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/combat/combat.dart';
import 'package:farming/layers/domain/entities/combat/arena_level_entity.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';
import 'package:farming/layers/domain/rules/arena_levels.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/rules/gear.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/rules/skills.dart';
import 'package:farming/layers/domain/world/extensions/hero_rules.dart';

import '../../../mocks/domain/game/balance_scenario_mock.dart';

double _winRate(ArenaLevelEntity level, HeroEntity hero, {int seeds = BalanceScenarioMock.seeds}) {
  var wins = 0;
  for (var seed = 0; seed < seeds; seed++) {
    final log = Combat.resolve(level: level, heroStats: hero.stats, skillLevels: hero.skillLevels, seed: seed);
    if (log.isVictory) wins++;
  }
  return wins / seeds;
}

HeroEntity _maxed(HeroEntity hero) => hero.copyWith(
  skillLevels: {for (final skill in hero.skills) skill: BalanceScenarioMock.maxedSkillLevel},
);

const _arenaResources = [Resource.gold, Resource.mana];

int _amount(Map<Resource, int> amounts, Resource resource) => amounts[resource] ?? 0;

int _spentOn(HeroEntity hero, Resource resource) {
  var total = 0;
  for (final slot in GearSlot.values) {
    for (var tier = 1; tier <= hero.tierOf(slot); tier++) {
      total += _amount(Gear.of(slot, tier).cost, resource);
    }
  }
  for (final skill in hero.skills) {
    for (var level = 1; level <= hero.levelOf(skill); level++) {
      total += _amount(Skills.byId(skill).costOf(level), resource);
    }
  }
  if (hero.skills.isNotEmpty) total += _amount(Blueprints.of(Skills.building).cost, resource);
  return total;
}

HeroEntity _expectedHero(ArenaLevelEntity level) => BalanceScenarioMock.expectedHero[level.id]!;

void main() {
  const levels = ArenaLevels.all;

  test('testWhenTheTableIsReadThenEveryArenaLevelHasAnExpectedHero', () {
    // given
    final table = BalanceScenarioMock.expectedHero;

    // when
    final ids = table.keys.toList();

    // then
    expect(ids, levels.map((level) => level.id));
  });

  test('testWhenTheHeroHasTheExpectedGearThenEachLevelAfterTheFirstIsWonMostButNotAllOfTheTime', () {
    // given
    final later = levels.skip(1);

    // when
    final first = _winRate(levels.first, _expectedHero(levels.first));
    final rates = {for (final level in later) level.id: _winRate(level, _expectedHero(level))};

    // then
    expect(first, greaterThanOrEqualTo(BalanceScenarioMock.minWinRate), reason: 'the first fight is meant to be won');
    for (final MapEntry(key: id, value: rate) in rates.entries) {
      expect(
        rate,
        inInclusiveRange(BalanceScenarioMock.minWinRate, BalanceScenarioMock.maxWinRate),
        reason: '${id.name} with the expected hero',
      );
    }
  });

  test('testWhenTheExpectedHeroFightsAThousandTimesThenEachLevelAfterTheFirstIsStillWonMostOfTheTime', () {
    // given
    final later = levels.skip(1);

    // when
    final rates = {
      for (final level in later) level.id: _winRate(level, _expectedHero(level), seeds: BalanceScenarioMock.manySeeds),
    };

    // then
    for (final MapEntry(key: id, value: rate) in rates.entries) {
      expect(rate, greaterThanOrEqualTo(BalanceScenarioMock.minWinRate), reason: '${id.name} over 1000 seeds');
    }
    expect(
      [
        for (final id in [
          ArenaLevelId.banditTrio,
          ArenaLevelId.barbarian,
          ArenaLevelId.wolfPack,
          ArenaLevelId.barbarianPair,
          ArenaLevelId.barbarianChief,
        ])
          rates[id],
      ],
      [0.866, 0.751, 0.719, 0.74, 0.608],
    );
  });

  test('testWhenTheExpectedHeroHasItsSkillsAtTheMaxLevelThenNoLevelIsWonMoreThanTheCeiling', () {
    // given
    final withSkills = levels.where((level) => _expectedHero(level).skills.isNotEmpty);

    // when
    final rates = [
      for (final level in withSkills)
        for (final seeds in [BalanceScenarioMock.seeds, BalanceScenarioMock.manySeeds])
          (level.id, seeds, _winRate(level, _maxed(_expectedHero(level)), seeds: seeds)),
    ];

    // then
    expect(rates, isNotEmpty);
    for (final (id, seeds, rate) in rates) {
      expect(rate, lessThanOrEqualTo(BalanceScenarioMock.maxWinRate), reason: '${id.name} maxed over $seeds seeds');
    }
  });

  test('testWhenTheHeroIsOneStepBehindWithItsSkillsAtTheMaxLevelThenEachLevelIsStillLostMostOfTheTime', () {
    // given
    final pairs = [
      for (var index = 1; index < levels.length; index++)
        if (_expectedHero(levels[index - 1]) != _expectedHero(levels[index]))
          (levels[index], _maxed(_expectedHero(levels[index - 1]))),
    ];

    // when
    final rates = {for (final (level, hero) in pairs) level.id: _winRate(level, hero)};

    // then
    for (final MapEntry(key: id, value: rate) in rates.entries) {
      expect(rate, lessThan(BalanceScenarioMock.maxWinRateOneStepBehind), reason: '${id.name} one step behind, maxed');
    }
  });

  test('testWhenTheHeroIsOneStepBehindThenEachLevelIsLostMostOfTheTime', () {
    // given
    final pairs = [
      for (var index = 1; index < levels.length; index++)
        if (_expectedHero(levels[index - 1]) != _expectedHero(levels[index]))
          (levels[index], _expectedHero(levels[index - 1])),
    ];

    // when
    final rates = {for (final (level, hero) in pairs) level.id: _winRate(level, hero)};

    // then
    expect(rates, isNotEmpty);
    for (final MapEntry(key: id, value: rate) in rates.entries) {
      expect(rate, lessThan(BalanceScenarioMock.maxWinRateOneStepBehind), reason: '${id.name} one step behind');
    }
  });

  test('testWhenEveryEarlierLevelIsWonOnceAndTheLastOneRepeatedThenTheExpectedGearIsAffordableInEveryResource', () {
    // given
    final budgets = <(String, int, int)>[];

    // when
    for (final resource in _arenaResources) {
      var firstRewards = 0;
      for (final (index, level) in levels.indexed) {
        final repeats = index == 0
            ? 0
            : BalanceScenarioMock.maxRepeats *
                  (_amount(levels[index - 1].reward, resource) ~/ Rules.repeatRewardDivisor);
        budgets.add((
          '${resource.name} ${level.id.name}',
          _spentOn(_expectedHero(level), resource),
          firstRewards + repeats,
        ));
        firstRewards += _amount(level.reward, resource);
      }
    }

    // then
    for (final (name, spent, earned) in budgets) {
      expect(spent, lessThanOrEqualTo(earned), reason: '$name: gear and skills cost $spent, the arena paid $earned');
    }
  });

  test('testWhenEveryLevelIsWonOnceThenTheManaPaysForEverySkill', () {
    // given
    const skills = Skills.all;

    // when
    final earned = levels.fold(0, (total, level) => total + _amount(level.reward, Resource.mana));
    final cost = skills.fold(0, (total, skill) => total + _amount(skill.costOf(1), Resource.mana));

    // then
    expect((earned, cost), (160, 95));
  });
}
