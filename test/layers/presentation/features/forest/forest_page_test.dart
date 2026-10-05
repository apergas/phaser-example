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
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_game.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_overlay.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/placement_bar.dart';

import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const invalidLevel = InvalidLevelException(data: 'missing width');

  late MockLevelRepository levelRepository;
  late MockNavigationService navigationService;

  setUpAll(loadSpanishTranslations);

  setUp(() async {
    rootBundle.clear();
    await configureDependencies(environment: DiEnvironment.dev);
    levelRepository = MockLevelRepository();
    navigationService = MockNavigationService();
    locator.allowReassignment = true;
    locator.registerFactory<LevelRepository>(() => levelRepository);
    locator.registerSingleton<NavigationService>(navigationService);
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('Condition not met within 10 seconds');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<ForestBloc> pumpGame(WidgetTester tester) async {
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());
    await tester.pumpWidget(MaterialApp(home: const ForestPage()));
    await pumpUntil(tester, () => find.byType(HudOverlay).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);
    return tester.element(find.byType(HudOverlay)).read<ForestBloc>();
  }

  testWidgets('testWhenTheLevelCannotBeLoadedThenTheErrorAndRetryAreShown', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);

    // when
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));
    await tester.pump();

    // then
    expect(find.text(invalidLevel.title), findsOneWidget);
    expect(find.text(invalidLevel.message), findsOneWidget);
    expect(find.text(Internationalize.forestRetry), findsOneWidget);
  });

  testWidgets('testWhenRetryIsTappedThenTheGameIsStartedAgain', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestRetry));
    await tester.pump();

    // then
    verify(levelRepository.load()).called(2);
  });

  testWidgets('testWhenTheLevelIsLoadingThenTheLoadingIndicatorIsShown', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());

    // when
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));

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

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));
    await tester.pump(const Duration(milliseconds: 200));

    // then
    final messages = verify(navigationService.showSnackbar(message: captureAnyNamed('message'))).captured;
    expect(messages, contains(Internationalize.forestMessageBlockedSite));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('testWhenTheGameStartsWithRealAssetsThenTheWorldIsReady', (tester) async {
    // given
    when(levelRepository.load()).thenAnswer((_) => ForestScenarioMock.empty());

    // when
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));
    await pumpUntil(tester, () => find.byType(GameWidget<ForestGame>).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);

    // then
    expect(game.world.scene, isNotNull);
  });
}
