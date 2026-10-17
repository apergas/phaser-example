// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:farming/core/error-handling/handlers/app_exception_handler.dart'
    as _i284;
import 'package:farming/core/services/logging/bloc/bloc_logger.dart' as _i296;
import 'package:farming/core/services/logging/hybrid-logger/custom_logger_impl.dart'
    as _i189;
import 'package:farming/core/services/logging/source/logger.dart' as _i195;
import 'package:farming/core/services/navigation/navify/navify_impl.dart'
    as _i769;
import 'package:farming/core/services/navigation/source/navigation_service.dart'
    as _i500;
import 'package:farming/layers/data/datasources/level/local/level_local_datasource_impl.dart'
    as _i783;
import 'package:farming/layers/data/datasources/level/source/level_local_datasource.dart'
    as _i1028;
import 'package:farming/layers/data/datasources/session/local/game_session_local_datasource_impl.dart'
    as _i23;
import 'package:farming/layers/data/datasources/session/source/game_session_local_datasource.dart'
    as _i576;
import 'package:farming/layers/data/repositories/level/level_repository_impl.dart'
    as _i571;
import 'package:farming/layers/data/repositories/level/mappers/building_mapper_dbo.dart'
    as _i959;
import 'package:farming/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart'
    as _i188;
import 'package:farming/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart'
    as _i875;
import 'package:farming/layers/data/repositories/level/mappers/level_mapper_dbo.dart'
    as _i459;
import 'package:farming/layers/data/repositories/level/mappers/position_mapper_dbo.dart'
    as _i453;
import 'package:farming/layers/data/repositories/level/mappers/rock_mapper_dbo.dart'
    as _i1063;
import 'package:farming/layers/data/repositories/level/mappers/tree_mapper_dbo.dart'
    as _i553;
import 'package:farming/layers/data/repositories/session/game_session_repository_impl.dart'
    as _i623;
import 'package:farming/layers/domain/repositories/level/level_repository.dart'
    as _i1036;
import 'package:farming/layers/domain/repositories/session/game_session_repository.dart'
    as _i663;
import 'package:farming/layers/domain/use-cases/arena/get_arena_use_case.dart'
    as _i281;
import 'package:farming/layers/domain/use-cases/arena/start_fight_use_case.dart'
    as _i630;
import 'package:farming/layers/domain/use-cases/game/advance_game_use_case.dart'
    as _i961;
import 'package:farming/layers/domain/use-cases/game/can_place_building_use_case.dart'
    as _i1071;
import 'package:farming/layers/domain/use-cases/game/chop_tree_use_case.dart'
    as _i803;
import 'package:farming/layers/domain/use-cases/game/construct_building_use_case.dart'
    as _i349;
import 'package:farming/layers/domain/use-cases/game/deposit_use_case.dart'
    as _i867;
import 'package:farming/layers/domain/use-cases/game/get_build_options_use_case.dart'
    as _i109;
import 'package:farming/layers/domain/use-cases/game/get_player_status_use_case.dart'
    as _i465;
import 'package:farming/layers/domain/use-cases/game/get_quests_use_case.dart'
    as _i94;
import 'package:farming/layers/domain/use-cases/game/get_stock_use_case.dart'
    as _i401;
import 'package:farming/layers/domain/use-cases/game/get_world_snapshot_use_case.dart'
    as _i579;
import 'package:farming/layers/domain/use-cases/game/mine_rock_use_case.dart'
    as _i50;
import 'package:farming/layers/domain/use-cases/game/move_player_use_case.dart'
    as _i844;
import 'package:farming/layers/domain/use-cases/game/resume_construction_use_case.dart'
    as _i282;
import 'package:farming/layers/domain/use-cases/game/start_game_use_case.dart'
    as _i1072;
import 'package:farming/layers/domain/use-cases/hero/buy_gear_use_case.dart'
    as _i357;
import 'package:farming/layers/domain/use-cases/hero/get_gear_options_use_case.dart'
    as _i122;
import 'package:farming/layers/domain/use-cases/hero/get_hero_status_use_case.dart'
    as _i201;
import 'package:farming/layers/domain/use-cases/hero/get_skill_options_use_case.dart'
    as _i1;
import 'package:farming/layers/domain/use-cases/hero/learn_skill_use_case.dart'
    as _i506;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i284.AppExceptionHandler>(() => _i284.AppExceptionHandler());
    gh.factory<_i959.BuildingMapperDBO>(() => _i959.BuildingMapperDBO());
    gh.factory<_i188.DecorationMapperDBO>(() => _i188.DecorationMapperDBO());
    gh.factory<_i875.GroundItemMapperDBO>(() => _i875.GroundItemMapperDBO());
    gh.factory<_i453.PositionMapperDBO>(() => _i453.PositionMapperDBO());
    gh.factory<_i1063.RockMapperDBO>(() => _i1063.RockMapperDBO());
    gh.factory<_i553.TreeMapperDBO>(() => _i553.TreeMapperDBO());
    gh.singleton<_i500.NavigationService>(() => _i769.NavifyImpl());
    gh.lazySingleton<_i576.GameSessionLocalDatasource>(
      () => _i23.GameSessionLocalDatasourceImpl(),
    );
    gh.singleton<_i195.Logger>(() => _i189.CustomLoggerImpl());
    gh.factory<_i1028.LevelLocalDatasource>(
      () => const _i783.LevelLocalDatasourceImpl(),
    );
    gh.factory<_i459.LevelMapperDBO>(
      () => _i459.LevelMapperDBO(
        positionMapperDBO: gh<_i453.PositionMapperDBO>(),
        treeMapperDBO: gh<_i553.TreeMapperDBO>(),
        decorationMapperDBO: gh<_i188.DecorationMapperDBO>(),
        groundItemMapperDBO: gh<_i875.GroundItemMapperDBO>(),
        rockMapperDBO: gh<_i1063.RockMapperDBO>(),
        buildingMapperDBO: gh<_i959.BuildingMapperDBO>(),
      ),
    );
    gh.factory<_i663.GameSessionRepository>(
      () => _i623.GameSessionRepositoryImpl(
        localDatasource: gh<_i576.GameSessionLocalDatasource>(),
        appExceptionHandler: gh<_i284.AppExceptionHandler>(),
      ),
    );
    gh.singleton<_i296.BlocLogger>(
      () => _i296.BlocLogger(logger: gh<_i195.Logger>()),
    );
    gh.factory<_i1036.LevelRepository>(
      () => _i571.LevelRepositoryImpl(
        localDatasource: gh<_i1028.LevelLocalDatasource>(),
        levelMapperDBO: gh<_i459.LevelMapperDBO>(),
        appExceptionHandler: gh<_i284.AppExceptionHandler>(),
      ),
    );
    gh.factory<_i281.GetArenaUseCase>(
      () => _i281.GetArenaUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i630.StartFightUseCase>(
      () => _i630.StartFightUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i961.AdvanceGameUseCase>(
      () => _i961.AdvanceGameUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i1071.CanPlaceBuildingUseCase>(
      () => _i1071.CanPlaceBuildingUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i803.ChopTreeUseCase>(
      () => _i803.ChopTreeUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i349.ConstructBuildingUseCase>(
      () => _i349.ConstructBuildingUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i867.DepositUseCase>(
      () => _i867.DepositUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i109.GetBuildOptionsUseCase>(
      () => _i109.GetBuildOptionsUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i465.GetPlayerStatusUseCase>(
      () => _i465.GetPlayerStatusUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i94.GetQuestsUseCase>(
      () => _i94.GetQuestsUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i401.GetStockUseCase>(
      () => _i401.GetStockUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i579.GetWorldSnapshotUseCase>(
      () => _i579.GetWorldSnapshotUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i50.MineRockUseCase>(
      () => _i50.MineRockUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i844.MovePlayerUseCase>(
      () => _i844.MovePlayerUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i282.ResumeConstructionUseCase>(
      () => _i282.ResumeConstructionUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i357.BuyGearUseCase>(
      () => _i357.BuyGearUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i122.GetGearOptionsUseCase>(
      () => _i122.GetGearOptionsUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i201.GetHeroStatusUseCase>(
      () => _i201.GetHeroStatusUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i1.GetSkillOptionsUseCase>(
      () => _i1.GetSkillOptionsUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i506.LearnSkillUseCase>(
      () => _i506.LearnSkillUseCase(
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    gh.factory<_i1072.StartGameUseCase>(
      () => _i1072.StartGameUseCase(
        levelRepository: gh<_i1036.LevelRepository>(),
        sessionRepository: gh<_i663.GameSessionRepository>(),
      ),
    );
    return this;
  }
}
