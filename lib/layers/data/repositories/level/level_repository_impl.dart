import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../domain/repositories/level/level_repository.dart';
import '../../../domain/world/world.dart';
import '../../datasources/level/source/level_local_datasource.dart';
import 'mappers/level_mapper_dbo.dart';

@Injectable(as: LevelRepository)
final class LevelRepositoryImpl implements LevelRepository {
  final LevelLocalDatasource _localDatasource;
  final LevelMapperDBO _levelMapperDBO;
  final AppExceptionHandler _appExceptionHandler;

  const LevelRepositoryImpl({
    required this._localDatasource,
    required this._levelMapperDBO,
    required this._appExceptionHandler,
  });

  @override
  World load() {
    try {
      return _levelMapperDBO.toEntity(_localDatasource.fetch());
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }
}
