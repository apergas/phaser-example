import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class NewGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const NewGameUseCase({
    required this._levelRepository,
    required this._sessionRepository,
    required this._saveRepository,
  });

  void call() {
    _saveRepository.clear();
    _sessionRepository.save(GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()));
  }
}
