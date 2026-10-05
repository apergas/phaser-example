import '../../entities/game/game_session_entity.dart';

abstract interface class GameSessionRepository {
  GameSessionEntity current();

  void save(GameSessionEntity session);
}
