import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../../mocks/presentation/features/forest/player_pose_mock.dart';

void main() {
  late MockNavigationService navigationService;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenStartedThenEmitsInProgressAndThenTheFirstFrame',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.treeEast(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    expect: () => [isA<ForestInProgress>(), isA<ForestSuccess>()],
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(data.world!.trees.single.id, 'tree-1');
      expect(data.player!.position, ForestScenarioMock.playerStart);
      expect(data.player!.facing, Facing.down);
      expect(data.player!.pose, PlayerPoseMock.idleWithoutAxe);
      expect(data.hud!.questBadge, '0/3');
      expect(data.placement, isNull);
      expect(data.effects, isEmpty);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheLevelCannotBeLoadedThenShowsTheErrorAndFails',
    build: () {
      // given
      return ForestBlocMock.make(
        ForestScenarioMock.empty(),
        navigationService: navigationService,
        loadError: AppExceptionMock.invalidLevel,
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    expect: () => [isA<ForestInProgress>(), isA<ForestFailure>()],
    verify: (bloc) {
      // then
      expect((bloc.state as ForestFailure).exception, isA<InvalidLevelException>());
      verify(
        navigationService.showErrorPopUp(
          title: anyNamed('title'),
          message: anyNamed('message'),
          buttonTitle: Internationalize.commonAccept,
        ),
      ).called(1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTickedBeforeStartingThenIgnoresIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    expect: () => <ForestState>[],
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ForestInitial>());
      verifyNever(navigationService.showSnackbar(message: anyNamed('message')));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenStartedAgainAfterAFailureThenBehavesLikeTheFirstStart',
    build: () {
      // given
      return ForestBlocMock.make(
        ForestScenarioMock.treeEast(),
        navigationService: navigationService,
        loadError: AppExceptionMock.invalidLevel,
        failingLoads: {2},
      );
    },
    act: (bloc) async {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
        ..add(const ForestStarted());
      await ForestBlocMock.processEvents();
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    wait: Duration.zero,
    expect: () => [
      isA<ForestInProgress>(),
      isA<ForestSuccess>(),
      isA<ForestSuccess>(),
      isA<ForestInProgress>(),
      isA<ForestFailure>(),
      isA<ForestInProgress>(),
      isA<ForestSuccess>(),
      isA<ForestSuccess>(),
    ],
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ForestSuccess>());
      expect(bloc.state.data.player!.position, ForestScenarioMock.playerStart);
      verify(navigationService.showSnackbar(message: Internationalize.forestMessageWelcome)).called(2);
    },
  );
}
