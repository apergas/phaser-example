import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/data/datasources/session/local/game_session_local_datasource_impl.dart';

import '../../../../../mocks/domain/entities/game/game_session_entity_mock.dart';

void main() {
  late GameSessionLocalDatasourceImpl sut;

  setUp(() {
    sut = GameSessionLocalDatasourceImpl();
  });

  test('testWhenNothingWasSetThenGetReturnsNull', () {
    // given
    // a fresh datasource

    // when
    final session = sut.get();

    // then
    expect(session, isNull);
  });

  test('testWhenSettingASessionThenGetReturnsTheSameInstance', () {
    // given
    final session = GameSessionEntityMock.make();

    // when
    sut.set(session);

    // then
    expect(sut.get(), same(session));
  });
}
