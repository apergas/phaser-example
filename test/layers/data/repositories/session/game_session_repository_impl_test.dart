import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/error-handling/exceptions/app_exceptions.dart';
import 'package:farming/layers/data/repositories/session/game_session_repository_impl.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';

void main() {
  late GameSessionRepositoryImpl sut;

  setUp(() {
    sut = GameSessionRepositoryImpl();
  });

  test('testWhenSavingThenCurrentReturnsTheSameSession', () {
    // given
    final session = GameSessionEntityMock.make();

    // when
    sut.save(session);
    final current = sut.current();

    // then
    expect(current, same(session));
  });

  test('testWhenSavingAgainThenCurrentReturnsTheLastSession', () {
    // given
    final first = GameSessionEntityMock.make();
    final second = GameSessionEntityMock.make();
    sut.save(first);

    // when
    sut.save(second);

    // then
    expect(sut.current(), same(second));
  });

  test('testWhenNoGameWasStartedThenCurrentThrowsNoGameInProgressException', () {
    // given
    // when
    void current() => sut.current();

    // then
    expect(current, throwsA(isA<NoGameInProgressException>()));
  });
}
