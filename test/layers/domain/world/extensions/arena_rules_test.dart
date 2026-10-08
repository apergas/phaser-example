import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/world/extensions/arena_rules.dart';

import '../../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';
import '../../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  group('isUnlocked', () {
    test('testWhenTheHeroIsNewThenOnlyTheFirstLevelIsUnlocked', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final unlocked = ArenaLevels.all.where(hero.isUnlocked).map((level) => level.id);

      // then
      expect(unlocked, [ArenaLevels.all.first.id]);
    });

    test('testWhenTheHeroClearedTheFirstLevelThenTheSecondIsUnlockedButNotTheThird', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final unlocked = (hero.isUnlocked(ArenaLevels.all[1]), hero.isUnlocked(ArenaLevels.all[2]));

      // then
      expect(unlocked, (true, false));
    });

    test('testWhenTheHeroClearedLevelsBeforeTheBeastsArrivedThenTheyStayOpenAndSoDoTheBeastsBehindThem', () {
      // given
      const hero = HeroEntityMock.beforeTheBeasts;

      // when
      final unlocked = ArenaLevels.all.where(hero.isUnlocked).map((level) => level.id);

      // then
      expect(unlocked, [
        ArenaLevelId.banditRookie,
        ArenaLevelId.wolf,
        ArenaLevelId.banditVeteran,
        ArenaLevelId.wolfPair,
      ]);
    });
  });

  group('hasCleared', () {
    test('testWhenTheHeroWonALevelThenItHasClearedItAndNoOther', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final cleared = (hero.hasCleared(ArenaLevelId.banditRookie), hero.hasCleared(ArenaLevelId.banditVeteran));

      // then
      expect(cleared, (true, false));
    });
  });

  group('rewardFor', () {
    test('testWhenTheLevelIsNotClearedThenTheRewardIsComplete', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookie);

      // then
      expect(reward, FundsMock.tenGold);
    });

    test('testWhenTheLevelIsClearedThenTheRewardIsAThird', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookie);

      // then
      expect(reward, FundsMock.threeGold);
    });

    test('testWhenARepeatedRewardRoundsToZeroThenThatResourceIsDropped', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookieWithWood);

      // then
      expect(reward, FundsMock.threeGold);
    });
  });

  group('afterFight', () {
    test('testWhenTheHeroWinsThenTheLevelIsClearedAndTheFightCounted', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final after = hero.afterFight(FightLogEntityMock.victoryOverBandit());

      // then
      expect(after, HeroEntityMock.afterFirstVictory);
    });

    test('testWhenTheHeroLosesThenOnlyTheFightIsCounted', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final after = hero.afterFight(FightLogEntityMock.defeatByBrute());

      // then
      expect(after, HeroEntityMock.afterFirstDefeat);
    });

    test('testWhenTheHeroWinsAClearedLevelAgainThenOnlyTheFightIsCounted', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final after = hero.afterFight(FightLogEntityMock.victoryOverBandit());

      // then
      expect(after, HeroEntityMock.veteranAfterAnotherFight);
    });
  });
}
