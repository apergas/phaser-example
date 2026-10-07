import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late StartFightUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = StartFightUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut(levelId: ArenaLevelId.banditRookie);

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheLevelIsLockedThenTheFightIsRefusedAndNothingChanges', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditVeteran);

    // then
    expect(result, FightResultEntityMock.locked);
    expect(session.world.hero, HeroEntityMock.mock);
    expect(session.world.funds.amount(Resource.gold), 0);
  });

  test('testWhenTheHeroWinsALevelForTheFirstTimeThenItIsPaidInFullAndCleared', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditRookie);

    // then
    expect(result, FightResultEntityMock.victoryOverBandit());
    expect(session.world.funds.amount(Resource.gold), 10);
    expect(session.world.hero, HeroEntityMock.afterFirstVictory);
  });

  test('testWhenTheHeroWinsAClearedLevelAgainThenItIsPaidAThird', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditRookie);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.log.rounds, played.advice), (true, 6, null));
    expect(played.log.reward, FundsMock.threeGold);
    expect(session.world.funds.amount(Resource.gold), 3);
    expect(session.world.hero, HeroEntityMock.veteranAfterAnotherFight);
  });

  test('testWhenTheHeroLosesThenNothingIsPaidAndAdviceIsGiven', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditVeteran);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.log.rounds, played.advice), (false, 6, FightAdvice.needAttack));
    expect(played.log.reward, isEmpty);
    expect(session.world.funds.amount(Resource.gold), 0);
    expect(session.world.hero, HeroEntityMock.veteranAfterAnotherFight);
  });
}
