import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class StartGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const StartGameUseCase({
    required this._levelRepository,
    required this._sessionRepository,
    required this._saveRepository,
  });

  void call() {
    _sessionRepository.save(
      _saveRepository.load() ?? GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()),
    );
  }
}
