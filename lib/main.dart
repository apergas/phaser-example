import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/di/di.dart';
import 'core/config/di/locator.dart';
import 'core/config/env/environment_constants.dart';
import 'core/services/logging/bloc/bloc_logger.dart';
import 'layers/presentation/app/container_app.dart';

void main() async {
  await _initialize();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es')],
      path: 'lib/core/assets/i18n/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      child: const ContainerApp(),
    ),
  );
}

Future<void> _initialize() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableBuildModes = [];

  await configureDependencies(environment: EnvironmentConstants.diEnvironment);

  Bloc.observer = locator<BlocLogger>();
}
