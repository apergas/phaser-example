import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/use-cases/game/advance_game_use_case.dart';

import '../../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';
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

  test('testWhenTheTenthTreeIsFelledThenItsQuestsAreCompletedInTheSameAdvance', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.withAxe,
      trees: [TreeEntityMock.mock],
      stats: StatsEntityMock.afterNineTrees,
    );
    final session = GameSessionEntityMock.playing(world);
    when(sessionRepository.current()).thenReturn(session);
    world.orderChop('tree-1');

    // when
    var events = sut(deltaMs: 50);
    while (!events.any((event) => event is TreeFelledEventEntity)) {
      events = sut(deltaMs: 50);
    }

    // then
    expect(events, containsAll([GameEventEntityMock.fellTenTreesCompleted, GameEventEntityMock.fellAnOakCompleted]));
    expect(session.quests.status(world)[0], QuestProgressEntityMock.gatherWoodAtSix);
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
