import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/assets/i18n/internationalize.dart';
import '../../../core/config/di/locator.dart';
import '../../../core/services/navigation/source/navigation_service.dart';
import '../theme/colors/custom_colors.dart';
import '../theme/custom_theme.dart';
import 'bloc/container_app_bloc.dart';

class ContainerApp extends StatelessWidget {
  const ContainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContainerAppBloc()..add(ContainerAppStarted()),
      child: MaterialApp(
        title: Internationalize.appTitle,
        navigatorKey: locator<NavigationService>().navigatorKey,
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

class ContainerAppView extends StatelessWidget {
  const ContainerAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContainerAppBloc, ContainerAppState>(
      builder: (context, state) {
        return Scaffold(backgroundColor: CustomColors.black, body: _bodyByState(state));
      },
    );
  }

  Widget _bodyByState(ContainerAppState state) {
    return switch (state) {
      ContainerAppInitial() => _loadingBody(),
      ContainerAppInProgress() => _loadingBody(),
      ContainerAppSuccess() => _emptyBody(),
      ContainerAppFailure() => _errorBody(),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _emptyBody() {
    return const SizedBox.expand();
  }

  Widget _errorBody() {
    return Center(child: Text(Internationalize.commonError));
  }
}
