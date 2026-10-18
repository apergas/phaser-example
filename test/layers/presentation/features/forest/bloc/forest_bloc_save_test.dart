import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/gear_id.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/domain/world/world.dart';
import 'package:farming/layers/presentation/features/forest/bloc/forest_bloc.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../../mocks/domain/game/upgrade_scenario_mock.dart';
import '../../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../../mocks/domain/world/funds_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late MockGameSaveRepository saveRepository;
  late List<String> shown;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    saveRepository = MockGameSaveRepository();
    shown = [];
    when(saveRepository.load()).thenReturn(null);
    when(navigationService.showSnackbar(message: anyNamed('message'))).thenAnswer((invocation) {
      shown.add(invocation.namedArguments[#message] as String);
    });
  });

  ForestBloc make(World world) =>
      ForestBlocMock.make(world, navigationService: navigationService, saveRepository: saveRepository);

  int saves() => verify(saveRepository.save(any)).callCount;

  group('testWhenTheGameRunsThenItSavesAfterImportantEventsOnly', () {
    late int whileChopping;

    blocTest<ForestBloc, ForestState>(
      'testWhenATreeIsHitThenNothingIsSavedAndWhenItFallsTheGameIsSaved',
      build: () => make(ForestScenarioMock.axeInHandWithTree()),
      act: (bloc) async {
        // given
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.treeCanopy, treeId: 'tree-1'));
        ForestBlocMock.tickFor(bloc, 3000);
        await ForestBlocMock.processEvents();
        whileChopping = verifyNever(saveRepository.save(any)).callCount;
        // when
        ForestBlocMock.tickFor(bloc, 4000);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(whileChopping, 0);
        expect(bloc.state.data.world!.trees, isEmpty);
        expect(saves(), 1);
      },
    );
  });

  group('testWhenTenSecondsPassThenTheGameIsSavedAndTheCountStartsAgain', () {
    late int at9999;
    late int at10000;
    late int at19999;

    blocTest<ForestBloc, ForestState>(
      'testWhenTenSecondsPassThenTheGameIsSavedAndTheCountStartsAgain',
      build: () => make(ForestScenarioMock.empty()),
      act: (bloc) async {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: 9999));
        await ForestBlocMock.processEvents();
        at9999 = verifyNever(saveRepository.save(any)).callCount;
        bloc.add(const ForestTicked(deltaMs: 1));
        await ForestBlocMock.processEvents();
        at10000 = verify(saveRepository.save(any)).callCount;
        bloc.add(const ForestTicked(deltaMs: 9999));
        await ForestBlocMock.processEvents();
        at19999 = verifyNever(saveRepository.save(any)).callCount;
        bloc.add(const ForestTicked(deltaMs: 1));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect((at9999, at10000, at19999), (0, 1, 0));
        expect(saves(), 1);
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenTheGameIsPausedThenItIsSaved',
    build: () => make(ForestScenarioMock.empty()),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestPaused());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(saves(), 1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenGearIsBoughtThenItIsSaved',
    build: () => make(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice)),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.shortSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(saves(), 1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenAnUpgradeIsBoughtThenItIsSaved',
    build: () => make(ForestScenarioMock.workshopWith(UpgradeScenarioMock.ironAxePrice)),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironAxe));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(saves(), 1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenASkillIsLearnedThenItIsSaved',
    build: () => make(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice)),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(saves(), 1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenAPurchaseFailsThenNothingIsSaved',
    build: () => make(ForestScenarioMock.workshopWith(UpgradeScenarioMock.fiveStoneShortOfTheIronAxe)),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironAxe))
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike))
        ..add(const ForestGearPurchaseRequested(gear: GearId.shortSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      verifyNever(saveRepository.save(any));
    },
  );

  group('testWhenComingBackFromTheArenaThenTheGameIsSaved', () {
    late int whileInTheArena;

    blocTest<ForestBloc, ForestState>(
      'testWhenComingBackFromTheArenaThenTheGameIsSaved',
      build: () => make(ForestScenarioMock.empty()),
      act: (bloc) async {
        // given
        Future<Object?> arena = Future<Object?>.delayed(const Duration(milliseconds: 10));
        when(navigationService.push(any)).thenAnswer((_) => arena);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestArenaRequested());
        await ForestBlocMock.processEvents();
        whileInTheArena = verifyNever(saveRepository.save(any)).callCount;
        await arena;
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        // then
        expect(whileInTheArena, 0);
        expect(saves(), 1);
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenSaveIsRequestedThenTheGameIsSavedAndItSaysSo',
    build: () => make(ForestScenarioMock.empty()),
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSaveRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(saves(), 1);
      expect(shown, [Internationalize.forestGameSaved]);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheRequestedSaveFailsThenThePopUpExplainsWhy',
    build: () {
      when(saveRepository.save(any)).thenThrow(AppExceptionMock.invalidSave);
      return make(ForestScenarioMock.empty());
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSaveRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(shown, isEmpty);
      verify(
        navigationService.showErrorPopUp(
          title: AppExceptionMock.invalidSave.title,
          message: AppExceptionMock.invalidSave.message,
          buttonTitle: anyNamed('buttonTitle'),
        ),
      ).called(1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenAnAutosaveFailsThenNothingIsShown',
    build: () {
      when(saveRepository.save(any)).thenThrow(AppExceptionMock.invalidSave);
      return make(ForestScenarioMock.empty());
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestPaused());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ForestSuccess>());
      expect(shown, isEmpty);
      verifyNever(
        navigationService.showErrorPopUp(
          title: anyNamed('title'),
          message: anyNamed('message'),
          buttonTitle: anyNamed('buttonTitle'),
        ),
      );
    },
  );

  group('testWhenANewGameIsRequestedThenTheSaveIsClearedTheLevelIsLoadedAndThePlayerIsGreetedAgain', () {
    late World played;

    blocTest<ForestBloc, ForestState>(
      'testWhenANewGameIsRequestedThenTheSaveIsClearedTheLevelIsLoadedAndThePlayerIsGreetedAgain',
      build: () {
        played = ForestScenarioMock.empty();
        return make(played);
      },
      act: (bloc) async {
        // given
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
          ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast));
        await ForestBlocMock.processEvents();
        // when
        bloc
          ..add(const ForestNewGameRequested())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
      },
      skip: 4,
      wait: Duration.zero,
      expect: () => [isA<ForestInProgress>(), isA<ForestSuccess>(), isA<ForestSuccess>()],
      verify: (bloc) {
        // then
        verify(saveRepository.clear()).called(1);
        expect(shown.where((message) => message == Internationalize.forestMessageWelcome), hasLength(2));
        expect(bloc.state.data.placement, isNull);
      },
    );
  });
}
