import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_game.dart';

import '../../../../helpers/spanish_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    loadSpanishTranslations();
    await configureDependencies(environment: DiEnvironment.dev);
  });

  tearDownAll(() => locator.reset());

  testWidgets('testWhenPumpingForestPageThenGameMountsAndBlocReachesSuccessWithRealAssets', (tester) async {
    // given
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: locator.get<NavigationService>().navigatorKey,
        home: const Scaffold(body: ForestPage()),
      ),
    );

    // when
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // then
    final bloc = tester.element(find.byType(GameWidget<ForestGame>)).read<ForestBloc>();
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    expect(bloc.state, isA<ForestSuccess>());
    expect(game.world.isReady, isTrue);
    expect(game.world.scene!.trees, isNotEmpty);
  });
}
