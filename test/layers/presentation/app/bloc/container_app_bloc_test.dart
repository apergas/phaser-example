import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/app/bloc/container_app_bloc.dart';

void main() {
  test('testWhenCreatedThenTheStateIsInitial', () {
    // given
    final bloc = ContainerAppBloc();

    // when
    final state = bloc.state;

    // then
    expect(state, isA<ContainerAppInitial>());
  });

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenEmitsInProgressAndSuccess',
    // given
    build: ContainerAppBloc.new,
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    expect: () => [isA<ContainerAppInProgress>(), isA<ContainerAppSuccess>()],
  );
}
