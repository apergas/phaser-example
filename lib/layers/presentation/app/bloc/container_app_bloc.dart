import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../features/forest/forest_page.dart';

part 'container_app_event.dart';
part 'container_app_state.dart';

class ContainerAppBloc extends Bloc<ContainerAppEvent, ContainerAppState> {
  final NavigationService _navigationService;

  ContainerAppBloc({required this._navigationService}) : super(const ContainerAppInitial()) {
    on<ContainerAppEvent>((event, emit) async {
      await switch (event) {
        ContainerAppStarted() => _onStarted(event, emit),
      };
    });
  }

  Future<void> _onStarted(ContainerAppStarted event, Emitter<ContainerAppState> emit) async {
    emit(ContainerAppInProgress(data: state.data));

    _navigationService.pushReplacement(ForestPage(routeObserver: _navigationService.routeObserver));

    emit(ContainerAppSuccess(data: state.data));
  }
}
