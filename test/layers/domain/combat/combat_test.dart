import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/fight_action.dart';
import 'package:farming/core/config/constants/enum/fight_advice.dart';
import 'package:farming/core/config/constants/enum/fight_outcome.dart';
import 'package:farming/core/config/constants/enum/fight_side.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/layers/domain/combat/combat.dart';
import 'package:farming/layers/domain/entities/combat/arena_level_entity.dart';
import 'package:farming/layers/domain/entities/combat/fight_log_entity.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';
import 'package:farming/layers/domain/rules/arena_levels.dart';
import 'package:farming/layers/domain/world/extensions/hero_rules.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';
import '../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';
import '../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/game/balance_scenario_mock.dart';

void main() {
  group('resolve', () {
    test('testWhenTheBaseHeroFightsTheRookieBanditThenTheGoldenLogIsAVictory', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {},
        seed: 0,
      );

      // then
      expect(log, FightLogEntityMock.victoryOverBanditBeforeReward());
    });

    test('testWhenAttackIsARangeThenEveryBlowPicksAValueInsideIt', () {
      // given
      const level = ArenaLevelEntityMock.duel;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {},
        seed: 0,
      );

      // then
      final heroDamage = log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.damage).toSet();
      final enemyDamage = log.turns.where((turn) => turn.actor == FightSide.enemy).map((turn) => turn.damage).toList();
      expect(heroDamage, {3, 4, 5});
      expect(enemyDamage.take(4).every((damage) => damage >= 6 && damage <= 8), isTrue);
    });

    test('testWhenResolvingTwiceWithTheSameSeedThenTheLogsAreEqual', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final first = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {SkillId.doubleStrike: 1, SkillId.dodge: 1},
        seed: 7,
      );
      final second = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {SkillId.doubleStrike: 1, SkillId.dodge: 1},
        seed: 7,
      );

      // then
      expect(second, first);
    });

    test('testWhenTheSeedChangesThenTheLogChanges', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {},
        seed: 1,
      );

      // then
      expect(log, isNot(FightLogEntityMock.victoryOverBanditBeforeReward()));
      expect((log.outcome, log.rounds), (FightOutcome.victory, 6));
    });

    test('testWhenTheBaseHeroFightsTheChiefThenItLosesInTwoRounds', () {
      // given
      const level = ArenaLevelEntityMock.barbarianChief;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {},
        seed: 0,
      );

      // then
      expect((log.outcome, log.rounds, log.turns.length), (FightOutcome.defeat, 2, 6));
      expect(log.turns.last.target, FightSide.hero);
      expect(log.turns.last.targetHealthAfter, 0);
      expect(log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.damage), [1, 1]);
    });

    test('testWhenTheBaseHeroDuelsThenTheGoldenLogIsANarrowDefeat', () {
      // given
      const level = ArenaLevelEntityMock.duel;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {},
        seed: 0,
      );

      // then
      expect(log, FightLogEntityMock.almostBeatDuelist());
    });

    test('testWhenAFullyGearedHeroFightsTheBruteThenTheGoldenLogIsADefeat', () {
      // given
      const level = ArenaLevelEntityMock.brute;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skillLevels: const {},
        seed: 0,
      );

      // then
      expect(log, FightLogEntityMock.defeatByBruteFullyGeared());
    });

    test('testWhenTheHeroHasDoubleStrikeThenTheExtraHitFollowsTheThirdAttack', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {SkillId.doubleStrike: 1},
        seed: 0,
      );

      // then
      final extra = log.turns[5];
      expect(
        (extra.action, extra.round, extra.actor, extra.damage, extra.targetHealthAfter),
        (
          FightAction.doubleStrike,
          3,
          FightSide.hero,
          4,
          4,
        ),
      );
      expect(log.turns.where((turn) => turn.action == FightAction.doubleStrike), hasLength(1));
      expect((log.outcome, log.rounds), (FightOutcome.victory, 4));
    });

    test('testWhenTheTargetFallsBeforeTheDoubleStrikeThenItHitsTheNextAliveEnemy', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {SkillId.doubleStrike: 1},
        seed: 0,
      );

      // then
      final kill = log.turns[8];
      final extra = log.turns[9];
      expect((kill.action, kill.targetIndex, kill.targetHealthAfter), (FightAction.hit, 0, 0));
      expect(
        (extra.action, extra.round, extra.targetIndex, extra.damage, extra.targetHealthAfter),
        (
          FightAction.doubleStrike,
          3,
          1,
          7,
          13,
        ),
      );
      expect(log.turns.where((turn) => turn.action == FightAction.doubleStrike).map((turn) => turn.round), [3, 6]);
      expect((log.outcome, log.rounds), (FightOutcome.victory, 7));
    });

    test('testWhenTheHeroHasDodgeThenSomeEnemyAttacksAreDodgedWithoutDamage', () {
      // given
      const level = ArenaLevelEntityMock.wall;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skillLevels: const {SkillId.dodge: 1},
        seed: 0,
      );

      // then
      final dodges = log.turns.where((turn) => turn.action == FightAction.dodge).toList();
      expect(dodges.map((turn) => turn.round), [11, 16, 18, 21, 22, 23]);
      expect(dodges.every((turn) => turn.actor == FightSide.enemy && turn.damage == 0), isTrue);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.hero).targetHealthAfter, 51);
      for (final dodge in dodges) {
        final index = log.turns.indexOf(dodge);
        final earlier = log.turns.sublist(0, index).where((turn) => turn.target == FightSide.hero);
        final healthBefore = earlier.isEmpty ? log.heroStats.health : earlier.last.targetHealthAfter;
        expect(dodge.targetHealthAfter, healthBefore);
      }
    });

    test('testWhenTheHeroHasSecondWindThenItHealsOnlyOnce', () {
      // given
      const level = ArenaLevelEntityMock.banditVeteran;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skillLevels: const {SkillId.secondWind: 1},
        seed: 0,
      );

      // then
      final heals = log.turns.where((turn) => turn.action == FightAction.secondWind).toList();
      expect(heals, hasLength(1));
      expect(
        (heals.single.round, heals.single.actor, heals.single.target, heals.single.targetHealthAfter),
        (
          5,
          FightSide.hero,
          FightSide.hero,
          17,
        ),
      );
      expect(log.turns[9].targetHealthAfter, 5);
      expect(log.turns[16].targetHealthAfter, 0);
      expect((log.outcome, log.rounds), (FightOutcome.defeat, 8));
    });

    test('testWhenNobodyCanHurtTheOtherThenTheFightStopsAtTheRoundLimitAsADefeat', () {
      // given
      const level = ArenaLevelEntityMock.wall;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skillLevels: const {},
        seed: 0,
      );

      // then
      expect((log.outcome, log.rounds, log.turns.length), (FightOutcome.defeat, Rules.maxFightRounds, 60));
      expect(log.turns.every((turn) => turn.damage == 1), isTrue);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.hero).targetHealthAfter, 45);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.enemy).targetHealthAfter, 70);
    });

    test('testWhenAnEnemyFallsThenItNoLongerAttacks', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {},
        seed: 0,
      );

      // then
      final fall = log.turns.indexWhere((turn) => turn.target == FightSide.enemy && turn.targetHealthAfter == 0);
      final afterFall = log.turns.skip(fall + 1);
      expect(fall, 8);
      expect(afterFall.where((turn) => turn.actor == FightSide.enemy && turn.actorIndex == 0), isEmpty);
      expect((log.outcome, log.rounds), (FightOutcome.victory, 9));
    });

    test('testWhenTheFirstEnemyFallsThenTheHeroTargetsTheNextAliveOne', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {},
        seed: 0,
      );

      // then
      final targets = log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.targetIndex);
      expect(targets, [0, 0, 0, 1, 1, 1, 2, 2, 2]);
    });
  });

  group('enemy skills', () {
    FightLogEntity fight(ArenaLevelId id, int seed, {ArenaLevelEntity Function(ArenaLevelEntity)? change}) {
      final level = ArenaLevels.byId(id);
      final hero = BalanceScenarioMock.expectedHero[id]!;
      return Combat.resolve(
        level: change == null ? level : change(level),
        heroStats: hero.stats,
        skillLevels: hero.skillLevels,
        seed: seed,
      );
    }

    test('testWhenTheExpectedHeroFightsTheBanditTrioWithSeedZeroThenAnEnemyDodgesInRoundFour', () {
      // given
      const seed = 0;

      // when
      final log = fight(ArenaLevelId.banditTrio, seed);

      // then
      final turn = log.turns[11];
      expect((turn.round, turn.actor, turn.target, turn.targetIndex), (4, FightSide.hero, FightSide.enemy, 1));
      expect((turn.action, turn.damage, turn.targetHealthAfter), (FightAction.dodge, 0, 26));
      expect((log.turns.length, log.outcome), (27, FightOutcome.victory));
    });

    test('testWhenTheExpectedHeroFightsTheBarbarianWithSeedTwentyFiveThenTheBarbarianStrikesTwice', () {
      // given
      const seed = 25;

      // when
      final log = fight(ArenaLevelId.barbarian, seed);

      // then
      final turn = log.turns[7];
      expect((turn.round, turn.actor, turn.actorIndex, turn.target), (3, FightSide.enemy, 0, FightSide.hero));
      expect((turn.action, turn.damage, turn.targetHealthAfter), (FightAction.doubleStrike, 5, 32));
      expect((log.turns.length, log.outcome), (18, FightOutcome.victory));
    });

    test('testWhenTheExpectedHeroFightsTheWolfPackWithSeedOneThenTheThirdWolfStrikesTwice', () {
      // given
      const seed = 1;

      // when
      final log = fight(ArenaLevelId.wolfPack, seed);

      // then
      final turn = log.turns[4];
      expect((turn.round, turn.actor, turn.actorIndex, turn.target), (1, FightSide.enemy, 2, FightSide.hero));
      expect((turn.action, turn.damage, turn.targetHealthAfter), (FightAction.doubleStrike, 4, 41));
      expect((log.turns.length, log.outcome), (22, FightOutcome.victory));
    });

    test('testWhenTheExpectedHeroFightsTheBarbarianPairWithSeedEightThenItLosesAlmostThere', () {
      // given
      const seed = 8;

      // when
      final log = fight(ArenaLevelId.barbarianPair, seed);

      // then
      final turn = log.turns[18];
      expect((turn.round, turn.actor, turn.actorIndex, turn.target), (6, FightSide.enemy, 1, FightSide.hero));
      expect((turn.action, turn.damage, turn.targetHealthAfter), (FightAction.doubleStrike, 6, 5));
      expect((log.turns.length, log.outcome), (23, FightOutcome.defeat));
      expect(Combat.adviceFor(log), FightAdvice.almostThere);
    });

    test('testWhenTheExpectedHeroFightsTheChiefWithSeedOneThenTheChiefGetsASecondWindAndWins', () {
      // given
      const seed = 1;

      // when
      final log = fight(ArenaLevelId.barbarianChief, seed);

      // then
      final strike = log.turns[4];
      final heal = log.turns[24];
      expect((strike.round, strike.actor, strike.actorIndex, strike.target), (1, FightSide.enemy, 2, FightSide.hero));
      expect((strike.action, strike.damage, strike.targetHealthAfter), (FightAction.doubleStrike, 1, 63));
      expect(
        (heal.round, heal.actor, heal.actorIndex, heal.target, heal.targetIndex),
        (
          6,
          FightSide.enemy,
          0,
          FightSide.enemy,
          0,
        ),
      );
      expect((heal.action, heal.targetHealthAfter), (FightAction.secondWind, 44));
      expect((log.turns.length, log.outcome), (31, FightOutcome.defeat));
      expect(Combat.adviceFor(log), FightAdvice.needDefense);
    });

    test('testWhenTheEnemySkillChanceIsZeroThenNoEnemyUsesASkill', () {
      // given
      const levels = [ArenaLevelId.banditTrio, ArenaLevelId.barbarianChief];

      // when
      final logs = [
        for (final id in levels)
          for (var seed = 0; seed < 20; seed++) fight(id, seed, change: (level) => level.copyWith(enemySkillChance: 0)),
      ];

      // then
      final enemySkills = logs
          .expand((log) => log.turns)
          .where(
            (turn) =>
                turn.actor == FightSide.enemy && turn.action != FightAction.hit && turn.action != FightAction.dodge,
          );
      expect(enemySkills, isEmpty);
    });

    test('testWhenTheChanceIsZeroThenTheLogIsTheOneOfALevelWithoutEnemySkills', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final withZero = Combat.resolve(
        level: level.copyWith(enemySkillChance: 0),
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {SkillId.doubleStrike: 1, SkillId.dodge: 1},
        seed: 7,
      );
      final withoutSkills = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skillLevels: const {SkillId.doubleStrike: 1, SkillId.dodge: 1},
        seed: 7,
      );

      // then
      expect(level.enemySkillChance, 0);
      expect(withZero, withoutSkills);
    });

    test('testWhenTheChiefFightsThenItGetsItsSecondWindAtMostOncePerFight', () {
      // given
      const seeds = 300;

      // when
      final heals = [
        for (var seed = 0; seed < seeds; seed++)
          fight(
            ArenaLevelId.barbarianChief,
            seed,
          ).turns.where((turn) => turn.actor == FightSide.enemy && turn.action == FightAction.secondWind).length,
      ];

      // then
      expect(heals.every((count) => count <= 1), isTrue);
      expect(heals.any((count) => count == 1), isTrue);
    });
  });

  group('skill levels', () {
    FightLogEntity fight(ArenaLevelId id, HeroEntity hero, Map<SkillId, int> skillLevels) => Combat.resolve(
      level: ArenaLevels.byId(id),
      heroStats: hero.stats,
      skillLevels: skillLevels,
      seed: 0,
    );

    test('testWhenTheDoubleStrikeLevelGrowsThenItsSecondBlowHitsHarder', () {
      // given
      const levels = [1, 2, 3];

      // when
      final logs = [
        for (final level in levels)
          fight(ArenaLevelId.barbarian, HeroEntityMock.bronzeAndChain, {SkillId.doubleStrike: level}),
      ];

      // then
      final strikes = logs.map((log) => log.turns[5]).toList();
      expect(strikes.map((turn) => (turn.round, turn.actor, turn.action)).toSet(), {
        (3, FightSide.hero, FightAction.doubleStrike),
      });
      expect(strikes.map((turn) => turn.damage), [6, 7, 8]);
      expect(strikes.map((turn) => turn.targetHealthAfter), [34, 33, 32]);
      expect(logs.map((log) => log.turns.length), [17, 15, 15]);
      expect(logs.map((log) => log.outcome).toSet(), {FightOutcome.victory});
    });

    test('testWhenTheDodgeLevelGrowsThenTheHeroDodgesMoreOfTheWolfPack', () {
      // given
      const levels = [1, 2, 3];

      // when
      final logs = [
        for (final level in levels) fight(ArenaLevelId.wolfPack, HeroEntityMock.bronzeAndChain, {SkillId.dodge: level}),
      ];

      // then
      final dodges = [
        for (final log in logs)
          log.turns.where((turn) => turn.target == FightSide.hero && turn.action == FightAction.dodge).toList(),
      ];
      expect(dodges.map((turns) => turns.length), [3, 5, 5]);
      expect(logs.map((log) => (log.turns.length, log.outcome)), [
        (23, FightOutcome.defeat),
        (24, FightOutcome.defeat),
        (25, FightOutcome.victory),
      ]);
      expect(
        [Combat.adviceFor(logs[0]), Combat.adviceFor(logs[1])],
        [FightAdvice.almostThere, FightAdvice.almostThere],
      );
      expect((logs[0].turns.indexOf(dodges[0].first), dodges[0].first.actorIndex), (6, 1));
      expect((logs[1].turns.indexOf(dodges[1].first), dodges[1].first.actorIndex), (6, 1));
      expect((logs[2].turns.indexOf(dodges[2].first), dodges[2].first.actorIndex), (1, 0));
      expect(dodges[2].first.targetHealthAfter, 55);
    });

    test('testWhenTheSecondWindLevelGrowsThenTheHeroHealsMoreAgainstTheChief', () {
      // given
      const levels = [1, 2, 3];

      // when
      final logs = [
        for (final level in levels)
          fight(ArenaLevelId.barbarianChief, HeroEntityMock.steelAndPlate, {SkillId.secondWind: level}),
      ];

      // then
      final heals = logs.map((log) => log.turns[16]).toList();
      final before = [for (final log in logs) log.turns.take(16).lastWhere((turn) => turn.target == FightSide.hero)];
      expect(heals.map((turn) => (turn.round, turn.actor, turn.action)).toSet(), {
        (4, FightSide.hero, FightAction.secondWind),
      });
      expect(before.map((turn) => turn.targetHealthAfter).toSet(), {21});
      expect(heals.map((turn) => turn.targetHealthAfter), [51, 59, 66]);
      expect(logs.map((log) => (log.turns.length, log.outcome)), [
        (46, FightOutcome.defeat),
        (49, FightOutcome.victory),
        (49, FightOutcome.victory),
      ]);
      expect(Combat.adviceFor(logs[0]), FightAdvice.almostThere);
    });
  });

  group('adviceFor', () {
    test('testWhenTheHeroWonThenThereIsNoAdvice', () {
      // given
      final log = FightLogEntityMock.victoryOverBandit();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, isNull);
    });

    test('testWhenTheEnemiesHadAQuarterOfTheirHealthLeftThenTheHeroWasAlmostThere', () {
      // given
      final log = FightLogEntityMock.almostBeatDuelist();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.almostThere);
    });

    test('testWhenTheHeroHitForTwoOrLessThenItNeedsAttack', () {
      // given
      final log = FightLogEntityMock.defeatByBrute();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.needAttack);
    });

    test('testWhenTheEnemyDodgedSomeBlowsThenTheDodgesDoNotLowerTheAverageDamage', () {
      // given
      final log = FightLogEntityMock.defeatByBruteThatDodges();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.needDefense);
    });

    test('testWhenTheHeroHitHardButFellEarlyThenItNeedsDefense', () {
      // given
      final log = FightLogEntityMock.defeatByBruteFullyGeared();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.needDefense);
    });
  });
}
