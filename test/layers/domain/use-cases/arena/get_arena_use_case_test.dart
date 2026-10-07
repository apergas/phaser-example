import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetArenaUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetArenaUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheHeroIsNewThenEveryLevelIsListedAndOnlyTheFirstIsOpen', () {
    // given
    when(sessionRepository.current())
        .thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock)));

    // when
    final arena = sut();

    // then
    expect(arena.heroPower, 31);
    expect(arena.levels.map((status) => status.level), ArenaLevels.all);
    expect(arena.levels.first, ArenaLevelStatusEntityMock.rookieForNewHero);
    expect(arena.levels.where((status) => status.isUnlocked).map((status) => status.level.id), [
      ArenaLevels.all.first.id,
    ]);
    expect(arena.levels.where((status) => status.isCleared), isEmpty);
  });

  test('testWhenTheHeroClearedTheFirstLevelThenItPaysAThirdAndOpensTheSecond', () {
    // given
    when(
      sessionRepository.current(),
    ).thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran)));

    // when
    final arena = sut();

    // then
    expect(arena.levels.first, ArenaLevelStatusEntityMock.rookieForVeteran);
    expect(arena.levels.where((status) => status.isUnlocked).map((status) => status.level.id), [
      ArenaLevels.all[0].id,
      ArenaLevels.all[1].id,
    ]);
    expect(arena.levels.where((status) => status.isCleared).map((status) => status.level.id), [
      ArenaLevelId.banditRookie,
    ]);
  });
}
