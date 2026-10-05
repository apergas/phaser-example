import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/assets/i18n/internationalize.dart';
import '../theme/colors/custom_colors.dart';
import 'bloc/container_app_bloc.dart';

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
      ContainerAppSuccess() => _loadingBody(),
      ContainerAppFailure() => _errorBody(),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator(color: CustomColors.hudAccent));
  }

  Widget _errorBody() {
    return Center(child: Text(Internationalize.commonError));
  }
}
