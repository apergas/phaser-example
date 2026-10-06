import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_action.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/core/config/constants/enum/fight_outcome.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/combat/combat.dart';
import 'package:rpg/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';
import '../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';
import '../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';

void main() {
  group('resolve', () {
    test('testWhenTheBaseHeroFightsTheRookieBanditThenTheGoldenLogIsAVictory', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

      // then
      expect(log, FightLogEntityMock.victoryOverBanditBeforeReward());
    });

    test('testWhenResolvingTwiceWithTheSameSeedThenTheLogsAreEqual', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final first = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {SkillId.doubleStrike, SkillId.dodge},
        seed: 7,
      );
      final second = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {SkillId.doubleStrike, SkillId.dodge},
        seed: 7,
      );

      // then
      expect(second, first);
    });

    test('testWhenTheSeedChangesThenTheLogChanges', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 1);

      // then
      expect(log, isNot(FightLogEntityMock.victoryOverBanditBeforeReward()));
      expect((log.outcome, log.rounds), (FightOutcome.victory, 6));
    });

    test('testWhenTheBaseHeroFightsTheChiefThenItLosesInTwoRounds', () {
      // given
      const level = ArenaLevelEntityMock.barbarianChief;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

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
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

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
        skills: const {},
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
        skills: const {SkillId.doubleStrike},
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
        skills: const {SkillId.doubleStrike},
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
        skills: const {SkillId.dodge},
        seed: 0,
      );

      // then
      final dodges = log.turns.where((turn) => turn.action == FightAction.dodge).toList();
      expect(dodges.map((turn) => turn.round), [11, 16, 18, 21, 22, 23]);
      expect(dodges.every((turn) => turn.actor == FightSide.enemy && turn.damage == 0), isTrue);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.hero).targetHealthAfter, 51);
    });

    test('testWhenTheHeroHasSecondWindThenItHealsOnlyOnce', () {
      // given
      const level = ArenaLevelEntityMock.banditVeteran;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skills: const {SkillId.secondWind},
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
      expect(log.turns[16].targetHealthAfter, 1);
      expect((log.outcome, log.rounds), (FightOutcome.defeat, 9));
    });

    test('testWhenNobodyCanHurtTheOtherThenTheFightStopsAtTheRoundLimitAsADefeat', () {
      // given
      const level = ArenaLevelEntityMock.wall;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skills: const {},
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
        skills: const {},
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
        skills: const {},
        seed: 0,
      );

      // then
      final targets = log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.targetIndex);
      expect(targets, [0, 0, 0, 1, 1, 1, 2, 2, 2]);
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
