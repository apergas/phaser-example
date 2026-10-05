part of 'container_app_bloc.dart';

final class ContainerAppData {
  const ContainerAppData();

  ContainerAppData copyWith() {
    return const ContainerAppData();
  }
}

sealed class ContainerAppState {
  final ContainerAppData data;

  const ContainerAppState({required this.data});
}

final class ContainerAppInitial extends ContainerAppState {
  const ContainerAppInitial() : super(data: const ContainerAppData());
}

final class ContainerAppInProgress extends ContainerAppState {
  const ContainerAppInProgress({required super.data});
}

final class ContainerAppSuccess extends ContainerAppState {
  const ContainerAppSuccess({required super.data});
}

final class ContainerAppFailure extends ContainerAppState {
  final CustomException exception;

  const ContainerAppFailure({required super.data, required this.exception});
}
