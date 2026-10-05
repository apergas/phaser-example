import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class StartGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;

  const StartGameUseCase({required this._levelRepository, required this._sessionRepository});

  void call() {
    _sessionRepository.save(GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()));
  }
}
