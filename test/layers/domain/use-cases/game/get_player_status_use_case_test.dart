import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';
import '../../../../mocks/core/error-handling/app_exception_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetPlayerStatusUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetPlayerStatusUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenChoppingHalfASwingThenStatusReportsChoppingProgressAndTarget', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree());
    when(sessionRepository.current()).thenReturn(session);
    session.world.orderChop('tree-1');
    session.world.advance(Rules.chopIntervalMs / 2);

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.chopping);
    expect(status.swingProgress, 0.5);
    expect(status.target, GameScenarioMock.halfSwingTreeTarget);
    expect(status.hasAxe, isTrue);
  });

  test('testWhenPlayerIsIdleThenStatusReportsIdleWithoutTarget', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.idle);
    expect(status.target, isNull);
    expect(status.swingProgress, 0);
    expect(status.wood, 10);
    expect(status.hasAxe, isFalse);
  });

  test('testWhenPlayerWalksThenStatusReportsWalkingAndDestination', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.playerAtFifty());
    when(sessionRepository.current()).thenReturn(session);
    session.world.movePlayerTo(GameScenarioMock.playerDestination);

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.walking);
    expect(status.target, GameScenarioMock.playerDestination);
  });

  test('testWhenPlayerHammersASiteThenStatusReportsConstructing', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withSeventeenWood());
    when(sessionRepository.current()).thenReturn(session);
    ConstructBuildingUseCase(sessionRepository: sessionRepository)(blueprint: BlueprintId.house, x: 300, y: 100);
    session.world.advanceFor(3000);

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.constructing);
  });
}
