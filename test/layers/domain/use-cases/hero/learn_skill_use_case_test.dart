import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/learn_skill_result.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/use-cases/hero/learn_skill_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';

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

  test('testWhenTheSkillIsAlreadyKnownThenNothingIsPaid', () {
    // given
    final world = playing(
      SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice, hero: HeroEntityMock.withDoubleStrike),
    );

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.alreadyKnown);
    expect(world.hero, HeroEntityMock.withDoubleStrike);
    expect(world.funds.amount(Resource.gold), 60);
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

  test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
    // given
    playing(SkillScenarioMock.withoutTower(hero: HeroEntityMock.withDoubleStrike));
    final missingBuilding = sut(id: SkillId.doubleStrike);
    playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrike));

    // when
    final alreadyKnown = sut(id: SkillId.doubleStrike);

    // then
    expect(missingBuilding, LearnSkillResult.missingBuilding);
    expect(alreadyKnown, LearnSkillResult.alreadyKnown);
  });

  test('testWhenEverythingIsInPlaceThenPaysLearnsTheSkillAndRaisesPower', () {
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
  });
}
