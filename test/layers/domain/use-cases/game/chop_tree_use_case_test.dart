import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ChopTreeUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ChopTreeUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenChoppingWithoutAxeThenReturnsNoAxe', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final result = sut(treeId: 'tree-1');

    // then
    expect(result, ChopResult.noAxe);
  });

  test('testWhenChoppingWithAxeThenReturnsOk', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree()));

    // when
    final result = sut(treeId: 'tree-1');

    // then
    expect(result, ChopResult.ok);
  });

  test('testWhenChoppingAnUnknownTreeThenReturnsUnknownTree', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree()));

    // when
    final result = sut(treeId: 'tree-99');

    // then
    expect(result, ChopResult.unknownTree);
  });
}
