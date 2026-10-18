import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/learn_skill_result.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/use-cases/hero/learn_skill_use_case.dart';
import 'package:farming/layers/domain/world/extensions/hero_rules.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late LearnSkillUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = LearnSkillUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenThereIsNoMageTowerThenTheSkillNeedsTheBuildingAndNothingIsPaid', () {
    // given
    final world = playing(SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.missingBuilding);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 60);
  });

  test('testWhenTheMageTowerIsStillBeingBuiltThenTheSkillNeedsTheBuilding', () {
    // given
    playing(SkillScenarioMock.withTowerUnderConstruction(funds: FundsMock.doubleStrikePrice));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.missingBuilding);
  });

  test('testWhenTheSkillIsTooExpensiveThenNothingIsPaidOrLearned', () {
    // given
    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.notEnoughResources);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 50);
  });

  test('testWhenThereIsEnoughGoldButNoManaThenNothingIsPaidOrLearned', () {
    // given
    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikeGoldWithoutMana));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.notEnoughResources);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 60);
    expect(world.funds.amount(Resource.mana), 0);
  });

  test('testWhenEverythingIsInPlaceThenPaysLearnsTheSkillAtLevelOneAndRaisesPower', () {
    // given
    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice));
    final powerBefore = world.hero.power;

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.ok);
    expect(world.hero, HeroEntityMock.withDoubleStrike);
    expect((powerBefore, world.hero.power), (31, 34));
    expect(world.funds.amount(Resource.gold), 0);
    expect(world.funds.amount(Resource.mana), 0);
  });

  test('testWhenTheSkillIsAtLevelOneThenItIsUpgradedToLevelTwoForTheSecondPrice', () {
    // given
    final world = playing(
      SkillScenarioMock.withTower(funds: FundsMock.doubleStrikeLevelTwoPrice, hero: HeroEntityMock.withDoubleStrike),
    );

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.upgraded);
    expect(world.hero, HeroEntityMock.withDoubleStrikeAtLevelTwo);
    expect((world.funds.amount(Resource.gold), world.funds.amount(Resource.mana)), (0, 0));
  });

  test('testWhenTheSkillIsAtLevelTwoThenItIsUpgradedToLevelThreeForTheThirdPrice', () {
    // given
    final world = playing(
      SkillScenarioMock.withTower(
        funds: FundsMock.doubleStrikeLevelThreePrice,
        hero: HeroEntityMock.withDoubleStrikeAtLevelTwo,
      ),
    );

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.upgraded);
    expect(world.hero, HeroEntityMock.withDoubleStrikeAtLevelThree);
    expect((world.funds.amount(Resource.gold), world.funds.amount(Resource.mana)), (0, 0));
  });

  test('testWhenTheSkillIsAtTheMaxLevelThenItIsMaxedAndNothingIsPaid', () {
    // given
    final world = playing(
      SkillScenarioMock.withTower(
        funds: FundsMock.doubleStrikeLevelThreePrice,
        hero: HeroEntityMock.withDoubleStrikeAtLevelThree,
      ),
    );

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.maxed);
    expect(world.hero, HeroEntityMock.withDoubleStrikeAtLevelThree);
    expect(world.funds.amount(Resource.gold), 135);
  });

  test('testWhenSeveralChecksFailThenTheTowerComesBeforeTheMaxLevelAndTheMaxLevelBeforeTheFunds', () {
    // given
    playing(SkillScenarioMock.withoutTower(hero: HeroEntityMock.withDoubleStrikeAtLevelThree));
    final missingBuilding = sut(id: SkillId.doubleStrike);
    playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrikeAtLevelThree));

    // when
    final maxed = sut(id: SkillId.doubleStrike);

    // then
    expect(missingBuilding, LearnSkillResult.missingBuilding);
    expect(maxed, LearnSkillResult.maxed);
  });
}
