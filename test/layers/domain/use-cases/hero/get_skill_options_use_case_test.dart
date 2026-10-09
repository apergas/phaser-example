import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/skill_option_state.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetSkillOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetSkillOptionsUseCase(sessionRepository: sessionRepository);
  });

  void playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
  }

  test('testWhenThereIsNoMageTowerThenEverySkillNeedsTheBuildingEvenIfItIsPaidFor', () {
    // given
    playing(SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice));

    // when
    final options = sut();

    // then
    expect(options.map((option) => option.state).toSet(), {SkillOptionState.needsBuilding});
    expect(options.first.missing, isEmpty);
  });

  test('testWhenTheNewHeroHasNoTowerAndNoGoldThenEverySkillSaysItsFullPriceIsMissing', () {
    // given
    playing(SkillScenarioMock.withoutTower());

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.newHeroWithoutTower);
  });

  test('testWhenTheTowerIsBuiltAndTheDoubleStrikeIsPaidForThenOnlyItIsAvailable', () {
    // given
    playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice));

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.readyToLearnDoubleStrike);
  });

  test('testWhenFundsAreShortThenTheSkillIsUnaffordableAndSaysWhatIsMissing', () {
    // given
    playing(SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike));

    // when
    final options = sut();

    // then
    expect(options.first, SkillOptionEntityMock.doubleStrikeTenGoldShort);
  });

  test('testWhenTheHeroKnowsASkillThenItIsListedAsKnownWithNothingMissing', () {
    // given
    playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrike));

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.afterLearningDoubleStrike);
  });
}
