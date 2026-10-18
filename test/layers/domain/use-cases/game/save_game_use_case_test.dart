import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/use-cases/game/save_game_use_case.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/game/save_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MockGameSaveRepository saveRepository;
  late SaveGameUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    saveRepository = MockGameSaveRepository();
    sut = SaveGameUseCase(sessionRepository: sessionRepository, saveRepository: saveRepository);
  });

  test('testWhenSavingThenTheCurrentSessionIsWrittenToTheSaveRepository', () {
    // given
    final session = SaveScenarioMock.session();
    when(sessionRepository.current()).thenReturn(session);

    // when
    sut();

    // then
    verify(saveRepository.save(session)).called(1);
  });

  test('testWhenTheSaveFailsThenTheErrorPropagates', () {
    // given
    final session = SaveScenarioMock.session();
    when(sessionRepository.current()).thenReturn(session);
    when(saveRepository.save(session)).thenThrow(AppExceptionMock.invalidSave);

    // when
    void save() => sut();

    // then
    expect(save, throwsA(AppExceptionMock.invalidSave));
  });

  test('testWhenThereIsNoGameThenNothingIsSaved', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void save() => sut();

    // then
    expect(save, throwsA(AppExceptionMock.noGameInProgress));
    verifyNever(saveRepository.save(any));
  });
}
