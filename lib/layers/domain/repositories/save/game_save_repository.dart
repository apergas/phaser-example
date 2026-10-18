import '../../entities/game/game_session_entity.dart';

abstract interface class GameSaveRepository {
  GameSessionEntity? load();

  void save(GameSessionEntity session);

  void clear();
}
