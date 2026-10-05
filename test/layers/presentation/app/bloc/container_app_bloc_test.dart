import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/presentation/app/bloc/container_app_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';

import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';

void main() {
  late MockNavigationService navigationService;

  setUp(() {
    navigationService = MockNavigationService();
    when(navigationService.pushReplacement<dynamic, dynamic>(any)).thenAnswer((_) async => null);
  });

  test('testWhenCreatedThenTheStateIsInitial', () {
    // given
    final bloc = ContainerAppBloc(navigationService: navigationService);

    // when
    final state = bloc.state;

    // then
    expect(state, isA<ContainerAppInitial>());
  });

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenEmitsInProgressAndSuccess',
    // given
    build: () => ContainerAppBloc(navigationService: navigationService),
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    expect: () => [isA<ContainerAppInProgress>(), isA<ContainerAppSuccess>()],
  );

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenItReplacesTheRouteWithTheForestPage',
    // given
    build: () => ContainerAppBloc(navigationService: navigationService),
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    verify: (_) => verify(navigationService.pushReplacement(argThat(isA<ForestPage>()))).called(1),
  );
}
