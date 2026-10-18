import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../../core/services/logging/source/logger.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/save/game_save_repository.dart';
import '../../datasources/save/source/game_save_local_datasource.dart';
import 'mappers/save_mapper_dbo.dart';

@Injectable(as: GameSaveRepository)
final class GameSaveRepositoryImpl implements GameSaveRepository {
  static const String _logHeader = 'GameSaveRepository';

  final GameSaveLocalDatasource _localDatasource;
  final SaveMapperDBO _saveMapperDBO;
  final AppExceptionHandler _appExceptionHandler;
  final Logger _logger;

  const GameSaveRepositoryImpl({
    required this._localDatasource,
    required this._saveMapperDBO,
    required this._appExceptionHandler,
    required this._logger,
  });

  @override
  GameSessionEntity? load() {
    try {
      final dbo = _localDatasource.load();
      return dbo == null ? null : _saveMapperDBO.toEntity(dbo);
    } catch (exception, stackTrace) {
      _handled(exception, stackTrace);
      return null;
    }
  }

  @override
  void save(GameSessionEntity session) {
    try {
      _localDatasource.save(_saveMapperDBO.toDBO(session));
    } catch (exception, stackTrace) {
      throw _handled(exception, stackTrace);
    }
  }

  @override
  void clear() {
    try {
      _localDatasource.clear();
    } catch (exception, stackTrace) {
      throw _handled(exception, stackTrace);
    }
  }

  AppException<Object?> _handled(Object exception, StackTrace stackTrace) {
    final error = _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    _logger.error(message: '${error.message} ($exception)', header: _logHeader, stackTrace: stackTrace);
    return error;
  }
}
