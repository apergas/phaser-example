import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/layers/data/datasources/session/source/game_session_local_datasource.dart';
import 'package:rpg/layers/data/repositories/session/game_session_repository_impl.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import 'game_session_repository_impl_test.mocks.dart';

@GenerateMocks([GameSessionLocalDatasource])
void main() {
  late MockGameSessionLocalDatasource localDatasource;
  late GameSessionRepositoryImpl sut;

  setUp(() {
    localDatasource = MockGameSessionLocalDatasource();
    sut = GameSessionRepositoryImpl(localDatasource: localDatasource, appExceptionHandler: AppExceptionHandler());
  });

  test('testWhenSavingThenCurrentReturnsTheSameSession', () {
    // given
    final session = GameSessionEntityMock.make();
    when(localDatasource.get()).thenReturn(session);

    // when
    sut.save(session);
    final current = sut.current();

    // then
    verify(localDatasource.set(session)).called(1);
    verify(localDatasource.get()).called(1);
    expect(current, same(session));
  });

  test('testWhenNoGameWasStartedThenCurrentThrowsNoGameInProgressException', () {
    // given
    when(localDatasource.get()).thenReturn(null);

    // when
    void current() => sut.current();

    // then
    expect(current, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenDatasourceFailsThenErrorIsRoutedThroughTheHandler', () {
    // given
    final session = GameSessionEntityMock.make();
    when(localDatasource.set(session)).thenThrow(StateError('storage unavailable'));

    // when
    void save() => sut.save(session);

    // then
    expect(save, throwsA(isA<GenericException>()));
  });
}
