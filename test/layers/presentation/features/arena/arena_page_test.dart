import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';
import 'package:rpg/layers/presentation/features/arena/arena_page.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_game.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_list.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../helpers/pump_until.dart';
import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../mocks/presentation/features/forest/game/asset_bundle_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    when(levelRepository.load()).thenReturn(ForestScenarioMock.empty());
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<ArenaGame> pumpArena(WidgetTester tester) async {
    locator.get<StartGameUseCase>()();
    await tester.pumpWidget(const MaterialApp(home: ArenaPage()));
    await pumpUntil(tester, () => find.byType(LevelList).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>)).game!;
    await pumpUntil(tester, () => game.isReady);
    return game;
  }

  testWidgets('testWhenOpenedThenTheStageTheLevelsAndTheFightButtonAreShown', (tester) async {
    // given
    // when
    final game = await pumpArena(tester);

    // then
    expect(game.scene!.fighters.keys, ['hero-0', 'enemy-0']);
    expect(find.text(ArenaLevelItemDataMock.rookieOpen.name), findsOneWidget);
    expect(find.text(Internationalize.arenaFight), findsOneWidget);
    expect(find.bySemanticsLabel(Internationalize.arenaAccessibilityStage), findsOneWidget);
  });

  testWidgets('testWhenAFightIsSkippedThenTheVictoryAndTheGoldAreShown', (tester) async {
    // given
    await pumpArena(tester);
    await tester.tap(find.text(Internationalize.arenaFight));
    await pumpUntil(tester, () => find.text(Internationalize.arenaSkip).evaluate().isNotEmpty);

    // when
    await tester.tap(find.text(Internationalize.arenaSkip));
    await pumpUntil(tester, () => find.byType(ResultPanel).evaluate().isNotEmpty);

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
    expect(find.text(Internationalize.arenaCleared), findsOneWidget);
  });

  testWidgets('testWhenTheReplayRunsThenTheGameTicksItToTheEnd', (tester) async {
    // given
    await pumpArena(tester);

    // when
    await tester.tap(find.text(Internationalize.arenaFight));
    for (var frame = 0; frame < 70 && find.byType(ResultPanel).evaluate().isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaFight), findsOneWidget);
  });

  testWidgets('testWhenThereIsNoGameThenTheErrorAndBackAreShown', (tester) async {
    // given
    await tester.pumpWidget(const MaterialApp(home: ArenaPage()));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.arenaBack));

    // then
    expect(find.text(Internationalize.errorNoGameInProgressMessage), findsOneWidget);
    verify(navigationService.pop()).called(1);
  });

  testWidgets('testWhenTheArtCannotBeLoadedThenTheErrorRetryAndBackAreShown', (tester) async {
    // given
    final bundle = AssetBundleFake(failingKey: ArenaAssetsLoader.prefix + ArenaAssetsLoader.atlasPath);
    locator.get<StartGameUseCase>()();

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(bundle: bundle, child: const ArenaPage()),
      ),
    );
    await pumpUntil(tester, () => find.text(Internationalize.errorGenericMessage).evaluate().isNotEmpty);

    // then
    expect(bundle.failedLoads, greaterThan(0));
    expect(find.text(Internationalize.arenaRetry), findsOneWidget);
    expect(find.text(Internationalize.arenaBack), findsWidgets);
  });
}
