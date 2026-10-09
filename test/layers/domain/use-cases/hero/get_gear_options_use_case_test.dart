import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetGearOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetGearOptionsUseCase(sessionRepository: sessionRepository);
  });

  void playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
  }

  test('testWhenANewHeroHasNoWorkshopsThenTheNextTiersNeedThemAndTheRestAreLocked', () {
    // given
    playing(GearScenarioMock.withoutWorkshops());

    // when
    final options = sut();

    // then
    expect(options, GearOptionEntityMock.newHeroWithoutWorkshops);
  });

  test('testWhenTheForgeIsBuiltAndTheSwordIsPaidForThenItIsAvailable', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final options = sut();

    // then
    expect(options[1], GearOptionEntityMock.shortSwordAvailable);
    expect(options[5].state, GearOptionState.needsBuilding);
  });

  test('testWhenFundsAreShortThenTheSwordIsUnaffordableAndSaysWhatIsMissing', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword));

    // when
    final options = sut();

    // then
    expect(options[1], GearOptionEntityMock.shortSwordFiveGoldShort);
  });

  test('testWhenTheHeroHasTheBestGearThenOnlyTheEquippedPiecesAreListed', () {
    // given
    playing(GearScenarioMock.withForgeAndArmory(hero: HeroEntityMock.fullyGeared));

    // when
    final options = sut();

    // then
    expect(options, GearOptionEntityMock.fullyGeared);
  });
}
