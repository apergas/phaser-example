import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/buy_gear_result.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/domain/use-cases/hero/buy_gear_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late BuyGearUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = BuyGearUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenThereIsNoForgeThenTheSwordNeedsTheBuildingAndNothingIsPaid', () {
    // given
    final world = playing(GearScenarioMock.withoutWorkshops(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.missingBuilding);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenTheForgeIsStillBeingBuiltThenTheSwordNeedsTheBuilding', () {
    // given
    playing(GearScenarioMock.withForgeUnderConstruction(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.missingBuilding);
  });

  test('testWhenOnlyTheForgeIsBuiltThenArmorStillNeedsTheArmory', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.leatherArmor);

    // then
    expect(result, BuyGearResult.missingBuilding);
  });

  test('testWhenSkippingATierThenItIsNotTheNextTier', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.ironSword);

    // then
    expect(result, BuyGearResult.notNextTier);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenBuyingTheEquippedGearAgainThenItIsNotTheNextTier', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice, hero: HeroEntityMock.withShortSword));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.notNextTier);
  });

  test('testWhenTheNextTierIsTooExpensiveThenNothingIsPaidOrEquipped', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.notEnoughResources);
    expect(world.hero, HeroEntityMock.mock);
    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (20, 5));
  });

  test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
    // given
    playing(GearScenarioMock.withoutWorkshops());
    final missingBuilding = sut(id: GearId.ironSword);
    playing(GearScenarioMock.withForge());

    // when
    final notNextTier = sut(id: GearId.ironSword);

    // then
    expect(missingBuilding, BuyGearResult.missingBuilding);
    expect(notNextTier, BuyGearResult.notNextTier);
  });

  test('testWhenEverythingIsInPlaceThenPaysAndEquipsTheSword', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.ok);
    expect(world.hero, HeroEntityMock.withShortSword);
    expect(world.hero.stats, CombatStatsEntityMock.heroWithShortSword);
    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (0, 0));
  });
}
