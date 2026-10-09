import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late StartFightUseCase startFight;
  late GetArenaUseCase getArena;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    startFight = StartFightUseCase(sessionRepository: sessionRepository);
    getArena = GetArenaUseCase(sessionRepository: sessionRepository);
  });

  GameSessionEntity playingWith(HeroEntity hero) {
    final session = GameSessionEntityMock.playing(WorldMock.withHero(hero));
    when(sessionRepository.current()).thenReturn(session);
    return session;
  }

  test('testWhenAFullyGearedHeroFightsEveryLevelInOrderThenItClearsTheWholeArena', () {
    // given
    final session = playingWith(HeroEntityMock.fullyGeared);
    final expectedGold = ArenaLevels.all.fold(0, (sum, level) => sum + (level.reward[Resource.gold] ?? 0));

    // when
    final results = [for (final level in ArenaLevels.all) startFight(levelId: level.id)];

    // then
    expect(results.every((result) => result is FightPlayedEntity && result.log.isVictory), isTrue);
    expect(session.world.funds.amount(Resource.gold), expectedGold);
    expect(session.world.hero.clearedLevels, ArenaLevels.all.map((level) => level.id).toSet());
    expect(session.world.hero.fightsFought, ArenaLevels.all.length);
    expect(getArena().levels.every((status) => status.isUnlocked && status.isCleared), isTrue);
  });

  test('testWhenTheArenaIsClearedThenReplayingTheFirstLevelPaysAThird', () {
    // given
    final session = playingWith(HeroEntityMock.fullyGeared);
    for (final level in ArenaLevels.all) {
      startFight(levelId: level.id);
    }
    final goldBefore = session.world.funds.amount(Resource.gold);

    final expectedRepeatGold =
        ArenaLevels.byId(ArenaLevelId.banditRookie).reward[Resource.gold]! ~/ Rules.repeatRewardDivisor;

    // when
    final result = startFight(levelId: ArenaLevelId.banditRookie);

    // then
    expect(result is FightPlayedEntity && result.log.isVictory, isTrue);
    expect(session.world.funds.amount(Resource.gold), goldBefore + expectedRepeatGold);
  });

  test('testWhenAGameFromBeforeTheBeastsGoesOnThenItKeepsItsLevelsAndCanFightTheWolfAndTheWolfPair', () {
    // given
    final session = playingWith(HeroEntityMock.beforeTheBeasts);

    // when
    final results = [
      startFight(levelId: ArenaLevelId.wolf),
      startFight(levelId: ArenaLevelId.banditVeteran),
      startFight(levelId: ArenaLevelId.wolfPair),
    ];

    // then
    expect(results, everyElement(isA<FightPlayedEntity>()));
    expect(
      session.world.hero.clearedLevels,
      containsAll([ArenaLevelId.banditRookie, ArenaLevelId.banditVeteran]),
    );
    final veteran = getArena().levels.firstWhere((status) => status.level.id == ArenaLevelId.banditVeteran);
    expect((veteran.isUnlocked, veteran.isCleared), (true, true));
  });

  test('testWhenANewHeroTriesTheLastLevelThenItIsLockedAndNothingChanges', () {
    // given
    final session = playingWith(HeroEntityMock.mock);

    // when
    final result = startFight(levelId: ArenaLevels.all.last.id);

    // then
    expect(result, FightResultEntityMock.locked);
    expect(session.world.hero, HeroEntityMock.mock);
  });
}
