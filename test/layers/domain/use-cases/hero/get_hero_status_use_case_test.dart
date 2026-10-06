import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_status_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetHeroStatusUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetHeroStatusUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheHeroHasBasicGearThenStatusHasBaseStatsAndPower', () {
    // given
    when(sessionRepository.current())
        .thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock)));

    // when
    final status = sut();

    // then
    expect(status, HeroStatusEntityMock.base);
  });
}
