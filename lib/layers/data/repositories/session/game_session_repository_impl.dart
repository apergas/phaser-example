import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/session/game_session_repository.dart';
import '../../datasources/session/source/game_session_local_datasource.dart';

@Injectable(as: GameSessionRepository)
final class GameSessionRepositoryImpl implements GameSessionRepository {
  final GameSessionLocalDatasource _localDatasource;
  final AppExceptionHandler _appExceptionHandler;

  const GameSessionRepositoryImpl({required this._localDatasource, required this._appExceptionHandler});

  @override
  GameSessionEntity current() {
    try {
      final session = _localDatasource.get();
      if (session == null) throw const NoGameInProgressException();
      return session;
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }

  @override
  void save(GameSessionEntity session) {
    try {
      _localDatasource.set(session);
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }
}
