import '../../../../domain/entities/game/game_session_entity.dart';

abstract interface class GameSessionLocalDatasource {
  GameSessionEntity? get();

  void set(GameSessionEntity session);
}
