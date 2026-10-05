import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error-handling/exceptions/custom_exception.dart';

part 'container_app_event.dart';
part 'container_app_state.dart';

class ContainerAppBloc extends Bloc<ContainerAppEvent, ContainerAppState> {
  ContainerAppBloc() : super(const ContainerAppInitial()) {
    on<ContainerAppEvent>((event, emit) async {
      await switch (event) {
        ContainerAppStarted() => _onStarted(event, emit),
      };
    });
  }

  Future<void> _onStarted(ContainerAppStarted event, Emitter<ContainerAppState> emit) async {
    emit(ContainerAppInProgress(data: state.data));

    emit(ContainerAppSuccess(data: state.data));
  }
}
