import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';
import '../../../../mocks/domain/entities/game/build_option_entity_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetBuildOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetBuildOptionsUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenResourcesAreNotEnoughThenHouseIsNotAffordable', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final options = sut();

    // then
    expect(options, [BuildOptionEntityMock.unaffordable]);
  });

  test('testWhenWoodEqualsTheCostThenHouseIsAffordable', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(WorldMock.withFifteenWood()));

    // when
    final options = sut();

    // then
    expect(options, [BuildOptionEntityMock.mock]);
  });

  test('testWhenWoodExceedsTheCostThenHouseIsAffordable', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(WorldMock.withSeventeenWood()));

    // when
    final options = sut();

    // then
    expect(options, [BuildOptionEntityMock.mock]);
  });
}
