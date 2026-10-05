import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MovePlayerUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = MovePlayerUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenMovePlayerAndAdvanceThenPlayerReachesThePoint', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.playerAtFifty());
    when(sessionRepository.current()).thenReturn(session);

    // when
    sut(x: GameScenarioMock.playerDestination.x, y: GameScenarioMock.playerDestination.y);
    session.world.advance(1000);

    // then
    expect(session.world.player.position, GameScenarioMock.playerDestination);
  });
}
