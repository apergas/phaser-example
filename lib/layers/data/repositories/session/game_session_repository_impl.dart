import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/session/game_session_repository.dart';

@LazySingleton(as: GameSessionRepository)
final class GameSessionRepositoryImpl implements GameSessionRepository {
  GameSessionEntity? _session;

  @override
  GameSessionEntity current() => _session ?? (throw const NoGameInProgressException());

  @override
  void save(GameSessionEntity session) {
    _session = session;
  }
}
