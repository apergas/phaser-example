// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart'
    as _i216;
import 'package:rpg/core/services/logging/bloc/bloc_logger.dart' as _i685;
import 'package:rpg/core/services/logging/hybrid-logger/custom_logger_impl.dart'
    as _i540;
import 'package:rpg/core/services/logging/source/logger.dart' as _i879;
import 'package:rpg/core/services/navigation/navify/navify_impl.dart' as _i192;
import 'package:rpg/core/services/navigation/source/navigation_service.dart'
    as _i100;
import 'package:rpg/layers/data/datasources/level/local/level_local_datasource_impl.dart'
    as _i25;
import 'package:rpg/layers/data/datasources/level/source/level_local_datasource.dart'
    as _i217;
import 'package:rpg/layers/data/datasources/session/local/game_session_local_datasource_impl.dart'
    as _i522;
import 'package:rpg/layers/data/datasources/session/source/game_session_local_datasource.dart'
    as _i684;
import 'package:rpg/layers/data/repositories/level/level_repository_impl.dart'
    as _i22;
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart'
    as _i112;
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart'
    as _i710;
import 'package:rpg/layers/data/repositories/level/mappers/level_mapper_dbo.dart'
    as _i491;
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart'
    as _i16;
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart'
    as _i690;
import 'package:rpg/layers/data/repositories/session/game_session_repository_impl.dart'
    as _i332;
import 'package:rpg/layers/domain/repositories/level/level_repository.dart'
    as _i38;
import 'package:rpg/layers/domain/repositories/session/game_session_repository.dart'
    as _i745;
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart'
    as _i785;
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart'
    as _i997;
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart'
    as _i763;
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart'
    as _i382;
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart'
    as _i886;
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart'
    as _i243;
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart'
    as _i606;
import 'package:rpg/layers/domain/use-cases/game/get_world_snapshot_use_case.dart'
    as _i903;
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart'
    as _i470;
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart'
    as _i368;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i216.AppExceptionHandler>(() => _i216.AppExceptionHandler());
    gh.factory<_i112.DecorationMapperDBO>(() => _i112.DecorationMapperDBO());
    gh.factory<_i710.GroundItemMapperDBO>(() => _i710.GroundItemMapperDBO());
    gh.factory<_i16.PositionMapperDBO>(() => _i16.PositionMapperDBO());
    gh.factory<_i690.TreeMapperDBO>(() => _i690.TreeMapperDBO());
    gh.singleton<_i879.Logger>(() => _i540.CustomLoggerImpl());
    gh.factory<_i217.LevelLocalDatasource>(
      () => const _i25.LevelLocalDatasourceImpl(),
    );
    gh.factory<_i491.LevelMapperDBO>(
      () => _i491.LevelMapperDBO(
        positionMapperDBO: gh<_i16.PositionMapperDBO>(),
        treeMapperDBO: gh<_i690.TreeMapperDBO>(),
        decorationMapperDBO: gh<_i112.DecorationMapperDBO>(),
        groundItemMapperDBO: gh<_i710.GroundItemMapperDBO>(),
      ),
    );
    gh.singleton<_i100.NavigationService>(() => _i192.NavifyImpl());
    gh.singleton<_i685.BlocLogger>(
      () => _i685.BlocLogger(logger: gh<_i879.Logger>()),
    );
    gh.lazySingleton<_i684.GameSessionLocalDatasource>(
      () => _i522.GameSessionLocalDatasourceImpl(),
    );
    gh.factory<_i745.GameSessionRepository>(
      () => _i332.GameSessionRepositoryImpl(
        localDatasource: gh<_i684.GameSessionLocalDatasource>(),
        appExceptionHandler: gh<_i216.AppExceptionHandler>(),
      ),
    );
    gh.factory<_i38.LevelRepository>(
      () => _i22.LevelRepositoryImpl(
        localDatasource: gh<_i217.LevelLocalDatasource>(),
        levelMapperDBO: gh<_i491.LevelMapperDBO>(),
        appExceptionHandler: gh<_i216.AppExceptionHandler>(),
      ),
    );
    gh.factory<_i368.StartGameUseCase>(
      () => _i368.StartGameUseCase(
        levelRepository: gh<_i38.LevelRepository>(),
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i785.AdvanceGameUseCase>(
      () => _i785.AdvanceGameUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i997.CanPlaceBuildingUseCase>(
      () => _i997.CanPlaceBuildingUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i763.ChopTreeUseCase>(
      () => _i763.ChopTreeUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i382.ConstructBuildingUseCase>(
      () => _i382.ConstructBuildingUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i886.GetBuildOptionsUseCase>(
      () => _i886.GetBuildOptionsUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i243.GetPlayerStatusUseCase>(
      () => _i243.GetPlayerStatusUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i606.GetQuestsUseCase>(
      () => _i606.GetQuestsUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i903.GetWorldSnapshotUseCase>(
      () => _i903.GetWorldSnapshotUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    gh.factory<_i470.MovePlayerUseCase>(
      () => _i470.MovePlayerUseCase(
        sessionRepository: gh<_i745.GameSessionRepository>(),
      ),
    );
    return this;
  }
}
