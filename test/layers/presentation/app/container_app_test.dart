import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/presentation/app/container_app.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';

import '../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../mocks/presentation/features/forest/forest_scenario_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLevelRepository levelRepository;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    await EasyLocalization.ensureInitialized();
    EasyLocalization.logger.enableBuildModes = [];
  });

  setUp(() async {
    await configureDependencies(environment: DiEnvironment.dev);
    levelRepository = MockLevelRepository();
    locator.allowReassignment = true;
    locator.registerFactory<LevelRepository>(() => levelRepository);
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('testWhenTheAppStartsThenTheForestPageReplacesTheInitialRoute', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());

    // when
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: 'lib/core/assets/i18n/translations',
        fallbackLocale: const Locale('es'),
        startLocale: const Locale('es'),
        child: const ContainerApp(),
      ),
    );
    for (var i = 0; i < 20 && find.byType(ForestPage).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // then
    expect(find.byType(ForestPage), findsOneWidget);
  });
}
