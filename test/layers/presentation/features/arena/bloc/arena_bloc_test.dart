import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
import 'package:rpg/core/config/constants/enum/arena/power_tone.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/world/world_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_bloc_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_effect_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late World world;
  late List<ArenaEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    world = WorldMock.withHero(HeroEntityMock.mock);
    effects = [];
  });

  blocTest<ArenaBloc, ArenaState>(
    'testWhenStartedThenListsEveryLevelOpensOnlyTheFirstAndSelectsIt',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(bloc.state, isA<ArenaSuccess>());
      expect(data.heroPower, 31);
      expect(data.levels.map((level) => level.id), ArenaLevels.all.map((level) => level.id));
      expect(data.levels[0], ArenaLevelItemDataMock.rookieOpen);
      expect(data.levels[1], ArenaLevelItemDataMock.wolfLocked);
      expect(data.levels[2], ArenaLevelItemDataMock.veteranLocked);
      expect(data.levels[5], ArenaLevelItemDataMock.trioLocked);
      expect(data.levels.last, ArenaLevelItemDataMock.chiefLocked);
      expect(data.selected, ArenaLevelId.banditRookie);
      expect(data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditIdle]);
      expect(data.canFight, isTrue);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenALevelPowerIsUpToAQuarterAboveTheHeroThenItsToneIsEven',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.dodgerAfterOneFight);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.heroPower, greaterThan(31));
      expect(bloc.state.data.levels[2].tone, PowerTone.even);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenThereIsNoGameThenFailsAndShowsTheError',
    build: () {
      // given
      return ArenaBlocMock.make(
        world,
        navigationService: navigationService,
        error: AppExceptionMock.noGameInProgress,
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ArenaFailure>());
      verify(
        navigationService.showErrorPopUp(
          title: AppExceptionMock.noGameInProgress.title,
          message: AppExceptionMock.noGameInProgress.message,
          buttonTitle: anyNamed('buttonTitle'),
        ),
      ).called(1);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenSelectingAnOpenLevelThenItIsSelectedAndItsEnemiesWait',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.wolfHunter);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditVeteran);
      expect(bloc.state.data.levels[2], ArenaLevelItemDataMock.veteranOpen);
      expect(bloc.state.data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.veteranBanditIdle]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheRookieIsBeatenThenTheWolfIsSelectedAndWaitsAlone',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.wolf);
      expect(bloc.state.data.levels[1], ArenaLevelItemDataMock.wolfOpen);
      expect(bloc.state.data.levels[2].id, ArenaLevelId.banditVeteran);
      expect(bloc.state.data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.wolfIdle]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenSelectingALockedLevelThenTheSelectionDoesNotChange',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditTrio));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditRookie);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenAFightIsRequestedThenItIsAlreadyPaidAndTheReplayStarts',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(world.funds.amount(Resource.gold), 10);
      expect(world.hero, HeroEntityMock.afterFirstVictory);
      expect((data.replay!.elapsedMs, data.replay!.turnIndex), (0, -1));
      expect(data.isReplaying, isTrue);
      expect(data.canFight, isFalse);
      expect(data.result, isNull);
      expect(data.levels[0], ArenaLevelItemDataMock.rookieOpen);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheFirstBlowLandsThenTheHeroSwingsAndTheBanditIsHurt',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 720);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final fighters = bloc.state.data.fighters;
      expect(fighters[0].pose, FighterPose.attack);
      expect(fighters[0].swingProgress, closeTo(320 / 600, 1e-9));
      expect(fighters[1], FighterRenderDataMock.rookieBanditHurt);
      expect(effects, [ArenaEffectMock.banditHitForFour]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheWolfStrikesThenItLeapsAtTheHero',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 1248);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.wolf);
      expect(bloc.state.data.fighters[1], FighterRenderDataMock.wolfLeaping(248 / 600));
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroStrikesTheSecondWolfOfThePackThenThatWolfIsItsTarget',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.packHunter);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.wolfPack))
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 4848);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.fighters.first;
      expect((hero.pose, hero.targetIndex), (FighterPose.attack, 1));
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayEndsThenEveryTurnPlayedOnceAndTheVictoryIsShown',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 6000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(effects, ArenaEffectMock.victoryOverBandit);
      expect(data.replay!.isFinished, isTrue);
      expect(data.result, ArenaResultDataMock.victoryTenGold);
      expect(data.fighters, [FighterRenderDataMock.heroAfterBeatingTheRookie, FighterRenderDataMock.rookieBanditDown]);
      expect(data.levels[0], ArenaLevelItemDataMock.rookieCleared);
      expect(data.levels[1], ArenaLevelItemDataMock.wolfOpen);
      expect(data.canFight, isTrue);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayIsSkippedThenOnlyTheEndIsPlayedAndTheResultIsShown',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, [ArenaEffectMock.won]);
      expect(bloc.state.data.replay!.isFinished, isTrue);
      expect(bloc.state.data.result, ArenaResultDataMock.victoryTenGold);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayIsRunningThenSelectingAndFightingAreIgnored',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditRookie))
        ..add(const ArenaFightRequested())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditRookie);
      expect(world.hero, HeroEntityMock.veteranAfterAnotherFight);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroLosesThenNoGoldIsPaidAndTheAdviceIsShown',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.wolfHunter);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(world.funds.amount(Resource.gold), 0);
      expect(effects, [ArenaEffectMock.lost]);
      expect(bloc.state.data.result, ArenaResultDataMock.defeatNeedAttack);
      expect(bloc.state.data.fighters.first.pose, FighterPose.down);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenRetryingAfterADefeatThenANewFightIsPlayed',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.wolfHunter);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped())
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(world.hero.fightsFought, 5);
      expect(bloc.state.data.isReplaying, isTrue);
      expect(bloc.state.data.result, isNull);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroDodgesThenTheDodgeIsPlayed',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.dodgerAfterOneFight);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 7000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects[3], ArenaEffectMock.heroDodged);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroStrikesTwiceThenTheSecondBlowIsFollowedByTheSkillName',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.withDoubleStrike);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 7000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.sublist(4, 7), [
        ArenaEffectMock.banditHitForFour,
        ArenaEffectMock.banditHitForFour,
        ArenaEffectMock.doubleStrikeUsed,
      ]);
      expect(effects.whereType<SkillUsedEffect>(), [ArenaEffectMock.doubleStrikeUsed]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroGetsASecondWindThenTheHealIsPlayedWithTheHealthGained',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteranWithSecondWind);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 12000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects[10], ArenaEffectMock.heroHealedTwelve);
      expect(effects[11], ArenaEffectMock.secondWindUsed);
      expect(effects.last, ArenaEffectMock.lost);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenClosedThenGoesBackToTheForest',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaClosed());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      verify(navigationService.pop()).called(1);
    },
  );
}
