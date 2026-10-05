import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/core/services/logging/bloc/bloc_logger.dart';
import 'package:rpg/core/services/logging/hybrid-logger/custom_logger_impl.dart';
import 'package:rpg/core/services/logging/source/logger.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';

void main() {
  tearDown(() async {
    await locator.reset();
  });

  test('testWhenConfiguringDependenciesThenTheCoreServicesAreRegistered', () async {
    // given
    const environment = DiEnvironment.dev;

    // when
    await configureDependencies(environment: environment);

    // then
    expect(locator<NavigationService>(), isA<NavifyImpl>());
    expect(locator<Logger>(), isA<CustomLoggerImpl>());
    expect(locator<BlocLogger>(), isA<BlocLogger>());
    expect(locator<AppExceptionHandler>(), isA<AppExceptionHandler>());
  });

  test('testWhenResolvingTheNavigationServiceTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);

    // when
    final first = locator<NavigationService>();
    final second = locator<NavigationService>();

    // then
    expect(identical(first, second), isTrue);
  });
}
