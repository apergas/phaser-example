import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/combat/combat.dart';
import 'package:rpg/layers/domain/entities/combat/arena_level_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/rules/gear.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/rules/skills.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';

import '../../../mocks/domain/game/balance_scenario_mock.dart';

double _winRate(ArenaLevelEntity level, HeroEntity hero) {
  var wins = 0;
  for (var seed = 0; seed < BalanceScenarioMock.seeds; seed++) {
    final log = Combat.resolve(level: level, heroStats: hero.stats, skills: hero.skills, seed: seed);
    if (log.isVictory) wins++;
  }
  return wins / BalanceScenarioMock.seeds;
}

int _gold(Map<Resource, int> cost) => cost[Resource.gold] ?? 0;

int _goldSpentOn(HeroEntity hero) {
  var total = 0;
  for (final slot in GearSlot.values) {
    for (var tier = 1; tier <= hero.tierOf(slot); tier++) {
      total += _gold(Gear.of(slot, tier).cost);
    }
  }
  for (final skill in hero.skills) {
    total += _gold(Skills.byId(skill).cost);
  }
  if (hero.skills.isNotEmpty) total += _gold(Blueprints.of(Skills.building).cost);
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

  test('testWhenEveryEarlierLevelIsWonOnceAndTheLastOneRepeatedThenTheExpectedGearIsAffordable', () {
    // given
    var firstRewards = 0;
    final budgets = <(String, int, int)>[];

    // when
    for (final (index, level) in levels.indexed) {
      final repeats = index == 0
          ? 0
          : BalanceScenarioMock.maxRepeats * (_gold(levels[index - 1].reward) ~/ Rules.repeatRewardDivisor);
      budgets.add((level.id.name, _goldSpentOn(_expectedHero(level)), firstRewards + repeats));
      firstRewards += _gold(level.reward);
    }

    // then
    for (final (name, spent, earned) in budgets) {
      expect(spent, lessThanOrEqualTo(earned), reason: '$name: gear and skills cost $spent, the arena paid $earned');
    }
  });
}
