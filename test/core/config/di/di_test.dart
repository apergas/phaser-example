import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/data/datasources/level/source/level_local_datasource.dart';
import 'package:farming/layers/data/datasources/save/source/game_save_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farming/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/rock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_building_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_decoration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_ground_item_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_hero_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_migration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_inventory_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_player_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_rock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stats_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stump_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_tree_mapper_dbo.dart';
import 'package:farming/layers/domain/repositories/level/level_repository.dart';
import 'package:farming/layers/domain/repositories/save/game_save_repository.dart';
import 'package:farming/layers/domain/repositories/session/game_session_repository.dart';
import 'package:farming/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:farming/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/buy_upgrade_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/can_place_building_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_build_options_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_stock_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_upgrade_options_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/mine_rock_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/move_player_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/new_game_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/resume_construction_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/save_game_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/start_game_use_case.dart';
import 'package:farming/layers/domain/use-cases/hero/buy_gear_use_case.dart';
import 'package:farming/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
import 'package:farming/layers/domain/use-cases/hero/get_hero_status_use_case.dart';
import 'package:farming/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:farming/layers/domain/use-cases/hero/learn_skill_use_case.dart';
import 'package:farming/core/config/di/di.dart';
import 'package:farming/core/config/di/di_environment.dart';
import 'package:farming/core/config/di/locator.dart';
import 'package:farming/core/error-handling/handlers/app_exception_handler.dart';
import 'package:farming/core/services/logging/bloc/bloc_logger.dart';
import 'package:farming/core/services/logging/hybrid-logger/custom_logger_impl.dart';
import 'package:farming/core/services/logging/source/logger.dart';
import 'package:farming/core/services/navigation/navify/navify_impl.dart';
import 'package:farming/core/services/navigation/source/navigation_service.dart';

import '../../../helpers/in_memory_preferences.dart';

void main() {
  setUp(useInMemoryPreferences);

  tearDown(() async {
    await locator.reset();
  });

  test('testWhenConfiguringDependenciesThenTheCoreServicesAreRegistered', () async {
    // given
    const environment = DiEnvironment.dev;

    // when
    await configureDependencies(environment: environment);

    // then
    expect(locator.get<NavigationService>(), isA<NavifyImpl>());
    expect(locator.get<Logger>(), isA<CustomLoggerImpl>());
    expect(locator.get<BlocLogger>(), isA<BlocLogger>());
    expect(locator.get<AppExceptionHandler>(), isA<AppExceptionHandler>());
  });

  test('testWhenResolvingTheNavigationServiceTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);

    // when
    final first = locator.get<NavigationService>();
    final second = locator.get<NavigationService>();

    // then
    expect(identical(first, second), isTrue);
  });

  test('testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    final registered = [
      locator.isRegistered<AdvanceGameUseCase>(),
      locator.isRegistered<BuyUpgradeUseCase>(),
      locator.isRegistered<CanPlaceBuildingUseCase>(),
      locator.isRegistered<ChopTreeUseCase>(),
      locator.isRegistered<ConstructBuildingUseCase>(),
      locator.isRegistered<GetBuildOptionsUseCase>(),
      locator.isRegistered<GetPlayerStatusUseCase>(),
      locator.isRegistered<GetQuestsUseCase>(),
      locator.isRegistered<GetStockUseCase>(),
      locator.isRegistered<GetUpgradeOptionsUseCase>(),
      locator.isRegistered<GetWorldSnapshotUseCase>(),
      locator.isRegistered<MineRockUseCase>(),
      locator.isRegistered<MovePlayerUseCase>(),
      locator.isRegistered<NewGameUseCase>(),
      locator.isRegistered<ResumeConstructionUseCase>(),
      locator.isRegistered<SaveGameUseCase>(),
      locator.isRegistered<StartGameUseCase>(),
      locator.isRegistered<BuyGearUseCase>(),
      locator.isRegistered<GetGearOptionsUseCase>(),
      locator.isRegistered<GetHeroStatusUseCase>(),
      locator.isRegistered<GetSkillOptionsUseCase>(),
      locator.isRegistered<LearnSkillUseCase>(),
      locator.isRegistered<GetArenaUseCase>(),
      locator.isRegistered<StartFightUseCase>(),
      locator.isRegistered<DecorationMapperDBO>(),
      locator.isRegistered<GroundItemMapperDBO>(),
      locator.isRegistered<LevelMapperDBO>(),
      locator.isRegistered<PositionMapperDBO>(),
      locator.isRegistered<RockMapperDBO>(),
      locator.isRegistered<TreeMapperDBO>(),
      locator.isRegistered<SaveBuildingMapperDBO>(),
      locator.isRegistered<SaveDecorationMapperDBO>(),
      locator.isRegistered<SaveGroundItemMapperDBO>(),
      locator.isRegistered<SaveHeroMapperDBO>(),
      locator.isRegistered<SaveInventoryMapperDBO>(),
      locator.isRegistered<SaveMapperDBO>(),
      locator.isRegistered<SaveMigrationMapperDBO>(),
      locator.isRegistered<SavePlayerMapperDBO>(),
      locator.isRegistered<SavePositionMapperDBO>(),
      locator.isRegistered<SaveRockMapperDBO>(),
      locator.isRegistered<SaveStatsMapperDBO>(),
      locator.isRegistered<SaveStockMapperDBO>(),
      locator.isRegistered<SaveStumpMapperDBO>(),
      locator.isRegistered<SaveTreeMapperDBO>(),
      locator.isRegistered<LevelRepository>(),
      locator.isRegistered<GameSessionRepository>(),
      locator.isRegistered<GameSaveRepository>(),
      locator.isRegistered<LevelLocalDatasource>(),
      locator.isRegistered<GameSaveLocalDatasource>(),
      locator.isRegistered<SharedPreferencesWithCache>(),
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
    expect(snapshot.trees.fold<int>(0, (total, tree) => total + tree.woodYield), 411);
    expect(snapshot.trees.first.kind, TreeKind.broad);
    expect(snapshot.rocks.length, 12);
    expect(snapshot.decorations.length, 94);
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

  test('testWhenResolvingTheSessionRepositoryTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);
    final first = locator.get<GameSessionRepository>();

    // when
    final second = locator.get<GameSessionRepository>();

    // then
    expect(identical(first, second), isTrue);
  });
}
