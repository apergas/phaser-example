import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockLevelRepository levelRepository;
  late MockGameSessionRepository sessionRepository;
  late StartGameUseCase sut;

  setUp(() {
    levelRepository = MockLevelRepository();
    sessionRepository = MockGameSessionRepository();
    sut = StartGameUseCase(levelRepository: levelRepository, sessionRepository: sessionRepository);
  });

  test('testWhenStartGameThenSavesLevelWorldWithFreshQuests', () {
    // given
    when(levelRepository.load()).thenReturn(GameScenarioMock.levelWithOneTree());

    // when
    sut();

    // then
    verify(levelRepository.load()).called(1);
    final saved = verify(sessionRepository.save(captureAny)).captured.single as GameSessionEntity;
    expect(saved.world.trees.map((tree) => tree.id), ['tree-1']);
    expect(saved.quests.status(saved.world).any((quest) => quest.isCompleted), isFalse);
  });

  test('testWhenStartGameWithLevelErrorThenErrorPropagates', () {
    // given
    when(levelRepository.load()).thenThrow(const InvalidLevelException(data: 'missing width'));

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<InvalidLevelException>()));
    verifyNever(sessionRepository.save(any));
  });
}
