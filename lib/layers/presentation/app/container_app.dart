import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/assets/i18n/internationalize.dart';
import '../../../core/config/di/locator.dart';
import '../../../core/services/navigation/source/navigation_service.dart';
import '../theme/custom_theme.dart';
import 'bloc/container_app_bloc.dart';
import 'container_app_view.dart';

class ContainerApp extends StatelessWidget {
  const ContainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ContainerAppBloc(navigationService: locator.get<NavigationService>())..add(ContainerAppStarted()),
      child: MaterialApp(
        title: Internationalize.appTitle,
        navigatorKey: locator<NavigationService>().navigatorKey,
        navigatorObservers: [locator<NavigationService>().routeObserver],
        theme: CustomTheme.data,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        home: const ContainerAppView(),
      ),
    );
  }
}
