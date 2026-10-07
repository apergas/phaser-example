import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets_loader.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_game.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_overlay.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/placement_bar.dart';

import '../../../../helpers/pump_until.dart';
import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../mocks/presentation/features/forest/game/asset_bundle_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const invalidLevel = AppExceptionMock.invalidLevel;

  late MockLevelRepository levelRepository;
  late MockNavigationService navigationService;
  late RouteObserver<ModalRoute<void>> routeObserver;

  setUpAll(loadSpanishTranslations);

  setUp(() async {
    rootBundle.clear();
    await configureDependencies(environment: DiEnvironment.dev);
    levelRepository = MockLevelRepository();
    navigationService = MockNavigationService();
    routeObserver = RouteObserver<ModalRoute<void>>();
    locator.allowReassignment = true;
    locator.registerFactory<LevelRepository>(() => levelRepository);
    locator.registerSingleton<NavigationService>(navigationService);
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<ForestBloc> pumpGame(WidgetTester tester) async {
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());
    await tester.pumpWidget(MaterialApp(home: ForestPage(routeObserver: routeObserver)));
    await pumpUntil(tester, () => find.byType(HudOverlay).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);
    return tester.element(find.byType(HudOverlay)).read<ForestBloc>();
  }

  testWidgets('testWhenTheLevelCannotBeLoadedThenTheErrorAndRetryAreShown', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);

    // when
    await tester.pumpWidget(MaterialApp(home: ForestPage(routeObserver: routeObserver)));
    await tester.pump();

    // then
    expect(find.text(invalidLevel.title), findsOneWidget);
    expect(find.text(invalidLevel.message), findsOneWidget);
    expect(find.text(Internationalize.forestRetry), findsOneWidget);
  });

  testWidgets('testWhenRetryIsTappedThenTheGameIsStartedAgain', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);
    await tester.pumpWidget(MaterialApp(home: ForestPage(routeObserver: routeObserver)));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestRetry));
    await tester.pump();

    // then
    verify(levelRepository.load()).called(2);
  });

  Future<void> pumpPageWithArt(WidgetTester tester, AssetBundleFake bundle) async {
    when(levelRepository.load()).thenReturn(ForestScenarioMock.empty());
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: ForestPage(routeObserver: routeObserver),
        ),
      ),
    );
  }

  testWidgets('testWhenTheArtCannotBeLoadedThenTheErrorAndRetryAreShown', (tester) async {
    // given
    final bundle = AssetBundleFake(failingKey: LpcAssetsLoader.prefix + LpcAssetsLoader.atlasPath);

    // when
    await pumpPageWithArt(tester, bundle);
    await pumpUntil(tester, () => find.text(Internationalize.errorGenericMessage).evaluate().isNotEmpty);

    // then
    expect(bundle.failedLoads, greaterThan(0));
    expect(find.text(Internationalize.errorGenericTitle), findsOneWidget);
    expect(find.text(Internationalize.errorGenericMessage), findsOneWidget);
    expect(find.text(Internationalize.forestRetry), findsOneWidget);
  });

  testWidgets('testWhenRetryIsTappedAfterTheArtFailedThenANewGameLoadsTheWorld', (tester) async {
    // given
    final bundle = AssetBundleFake(failingKey: LpcAssetsLoader.prefix + LpcAssetsLoader.atlasPath);
    await pumpPageWithArt(tester, bundle);
    await pumpUntil(tester, () => find.text(Internationalize.forestRetry).evaluate().isNotEmpty);
    final failedGame = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    bundle.isFailing = false;

    // when
    await tester.tap(find.text(Internationalize.forestRetry));
    await pumpUntil(tester, () {
      final widgets = find.byType(GameWidget<ForestGame>).evaluate();
      if (widgets.isEmpty) return false;
      final game = (widgets.single.widget as GameWidget<ForestGame>).game!;
      return game != failedGame && game.world.isReady;
    });

    // then
    expect(find.text(Internationalize.errorGenericMessage), findsNothing);
    expect(find.text(Internationalize.forestRetry), findsNothing);
    verify(levelRepository.load()).called(2);
  });

  testWidgets('testWhenTheLevelIsLoadingThenTheLoadingIndicatorIsShown', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());

    // when
    await tester.pumpWidget(MaterialApp(home: ForestPage(routeObserver: routeObserver)));

    // then
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(GameWidget<ForestGame>), findsNothing);
  });

  testWidgets('testWhenTheGameStartsThenTheWorldAndTheHudAreShownWithTheAccessibilityLabel', (tester) async {
    // given
    // when
    await pumpGame(tester);

    // then
    expect(find.byType(GameWidget<ForestGame>), findsOneWidget);
    expect(find.byType(HudOverlay), findsOneWidget);
    expect(find.bySemanticsLabel(Internationalize.forestAccessibilityGameWorld), findsOneWidget);
    expect(find.byType(PlacementBar), findsNothing);
  });

  testWidgets('testWhenEscapeIsPressedDuringPlacementThenThePlacementIsCancelled', (tester) async {
    // given
    final bloc = await pumpGame(tester);
    bloc.add(const ForestBuildRequested(blueprint: BlueprintId.house));
    await pumpUntil(tester, () => bloc.state.data.placement != null);

    // when
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpUntil(tester, () => bloc.state.data.placement == null);

    // then
    expect(bloc.state.data.placement, isNull);
    expect(find.byType(PlacementBar), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('testWhenPlacingOnATouchPlatformThenThePlacementBarCancelsThePlacement', (tester) async {
    // given
    final bloc = await pumpGame(tester);
    bloc.add(const ForestBuildRequested(blueprint: BlueprintId.house));
    await pumpUntil(tester, () => find.byType(PlacementBar).evaluate().isNotEmpty);

    // when
    await tester.tap(find.text(Internationalize.forestPlacementCancel));
    await pumpUntil(tester, () => find.byType(PlacementBar).evaluate().isEmpty);

    // then
    expect(bloc.state.data.placement, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('testWhenPlacingOnATouchPlatformThenThePlacementBarConfirmsThePlacementAtTheGhostPosition', (
    tester,
  ) async {
    // given
    final bloc = await pumpGame(tester);
    bloc.add(const ForestBuildRequested(blueprint: BlueprintId.house));
    await pumpUntil(tester, () => find.byType(PlacementBar).evaluate().isNotEmpty);
    bloc.add(const ForestPointerMoved(position: ForestScenarioMock.freeSite));
    await pumpUntil(tester, () => bloc.state.data.placement?.position == ForestScenarioMock.freeSite);

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));
    await pumpUntil(tester, () => find.byType(PlacementBar).evaluate().isEmpty);

    // then
    expect(bloc.state.data.placement, isNull);
    final messages = verify(navigationService.showSnackbar(message: captureAnyNamed('message'))).captured;
    expect(messages, contains(Internationalize.forestMessageBuildingStarted));
    expect(messages, isNot(contains(Internationalize.forestMessageBlockedSite)));
    expect(find.byType(PlacementBar), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('testWhenTheGameStartsWithRealAssetsThenTheWorldIsReady', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.empty());

    // when
    await tester.pumpWidget(MaterialApp(home: ForestPage(routeObserver: routeObserver)));
    await pumpUntil(tester, () => find.byType(GameWidget<ForestGame>).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);

    // then
    expect(game.world.scene, isNotNull);
  });

  testWidgets('testWhenAPageIsPushedOverTheForestThenTheGamePausesAndResumesOnReturn', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [routeObserver],
        home: ForestPage(routeObserver: routeObserver),
      ),
    );
    await pumpUntil(tester, () => find.byType(HudOverlay).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);
    final bloc = tester.element(find.byType(HudOverlay)).read<ForestBloc>();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    // when
    navigator.push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final stateWhilePaused = bloc.state;
    await tester.pump(const Duration(milliseconds: 100));
    final pausedAfterFrames = game.paused;
    final ticksWhilePaused = !identical(bloc.state, stateWhilePaused);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // then
    expect(pausedAfterFrames, isTrue);
    expect(ticksWhilePaused, isFalse);
    expect(game.paused, isFalse);
  });
}
