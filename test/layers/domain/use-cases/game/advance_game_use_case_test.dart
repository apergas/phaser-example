import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../../mocks/domain/entities/game/quest_progress_entity_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late AdvanceGameUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = AdvanceGameUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenPickingUpTheAxeThenQuestIsCompletedAndNextOneIsCurrent', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.axeNextToPlayer());
    when(sessionRepository.current()).thenReturn(session);
    session.world.movePlayerTo(GameScenarioMock.axeSpot);

    // when
    final events = sut(deltaMs: 200);

    // then
    expect(events, contains(GameEventEntityMock.pickUpAxeCompleted));
    expect(session.quests.status(session.world)[1], QuestProgressEntityMock.gatherWoodCurrent);
  });

  test('testWhenNothingHappensThenReturnsNoEvents', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final events = sut(deltaMs: 16);

    // then
    expect(events, isEmpty);
  });
}
