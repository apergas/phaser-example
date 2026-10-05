import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/data/datasources/level/source/level_local_datasource.dart';
import 'package:rpg/layers/data/datasources/session/source/game_session_local_datasource.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/domain/repositories/session/game_session_repository.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/core/services/logging/bloc/bloc_logger.dart';
import 'package:rpg/core/services/logging/hybrid-logger/custom_logger_impl.dart';
import 'package:rpg/core/services/logging/source/logger.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';

void main() {
  tearDown(() async {
    await locator.reset();
  });

  test('testWhenConfiguringDependenciesThenTheCoreServicesAreRegistered', () async {
    // given
    const environment = DiEnvironment.dev;

    // when
    await configureDependencies(environment: environment);

    // then
    expect(locator<NavigationService>(), isA<NavifyImpl>());
    expect(locator<Logger>(), isA<CustomLoggerImpl>());
    expect(locator<BlocLogger>(), isA<BlocLogger>());
    expect(locator<AppExceptionHandler>(), isA<AppExceptionHandler>());
  });

  test('testWhenResolvingTheNavigationServiceTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);

    // when
    final first = locator<NavigationService>();
    final second = locator<NavigationService>();

    // then
    expect(identical(first, second), isTrue);
  });

  test('testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    final registered = [
      locator.isRegistered<StartGameUseCase>(),
      locator.isRegistered<MovePlayerUseCase>(),
      locator.isRegistered<ChopTreeUseCase>(),
      locator.isRegistered<CanPlaceBuildingUseCase>(),
      locator.isRegistered<ConstructBuildingUseCase>(),
      locator.isRegistered<AdvanceGameUseCase>(),
      locator.isRegistered<GetPlayerStatusUseCase>(),
      locator.isRegistered<GetWorldSnapshotUseCase>(),
      locator.isRegistered<GetBuildOptionsUseCase>(),
      locator.isRegistered<GetQuestsUseCase>(),
      locator.isRegistered<LevelRepository>(),
      locator.isRegistered<GameSessionRepository>(),
      locator.isRegistered<LevelLocalDatasource>(),
      locator.isRegistered<GameSessionLocalDatasource>(),
      locator.isRegistered<AppExceptionHandler>(),
      locator.isRegistered<NavigationService>(),
    ];

    // when
    final allRegistered = registered.every((isRegistered) => isRegistered);

    // then
    expect(allRegistered, isTrue);
  });

  test('testWhenStartingAGameThenTheProceduralForestIsLoaded', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    final startGame = locator.get<StartGameUseCase>();

    // when
    startGame();
    final snapshot = locator.get<GetWorldSnapshotUseCase>()();

    // then
    expect(snapshot.trees.length, 70);
    expect(snapshot.trees.fold<int>(0, (total, tree) => total + tree.woodYield), 388);
    expect(snapshot.trees.first.kind, TreeKind.broad);
    expect(snapshot.decorations.length, greaterThanOrEqualTo(40));
  });

  test('testWhenUseCasesAreResolvedSeparatelyThenTheyShareTheSameGame', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    locator.get<StartGameUseCase>()();

    // when
    locator.get<MovePlayerUseCase>()(x: 800, y: 500);
    locator.get<AdvanceGameUseCase>()(deltaMs: 2000);

    // then
    expect(locator.get<GetPlayerStatusUseCase>()().position.y, 500);
  });

  test('testWhenResolvingTheSessionDatasourceTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    final first = locator.get<GameSessionLocalDatasource>();

    // when
    final second = locator.get<GameSessionLocalDatasource>();

    // then
    expect(identical(first, second), isTrue);
  });
}
