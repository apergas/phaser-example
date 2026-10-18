import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/entities/game/game_session_entity.dart';
import 'package:farming/layers/domain/use-cases/game/new_game_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockLevelRepository levelRepository;
  late MockGameSessionRepository sessionRepository;
  late MockGameSaveRepository saveRepository;
  late NewGameUseCase sut;

  setUp(() {
    levelRepository = MockLevelRepository();
    sessionRepository = MockGameSessionRepository();
    saveRepository = MockGameSaveRepository();
    sut = NewGameUseCase(
      levelRepository: levelRepository,
      sessionRepository: sessionRepository,
      saveRepository: saveRepository,
    );
  });

  test('testWhenStartingANewGameThenTheSaveIsClearedAndTheLevelStartsWithNoQuestsDone', () {
    // given
    when(levelRepository.load()).thenReturn(GameScenarioMock.levelWithOneTree());

    // when
    sut();

    // then
    verifyInOrder([saveRepository.clear(), levelRepository.load()]);
    final session = verify(sessionRepository.save(captureAny)).captured.single as GameSessionEntity;
    expect(session.world.trees.map((tree) => tree.id), ['tree-1']);
    expect(session.quests.completed, isEmpty);
    verifyNever(saveRepository.load());
  });
}
