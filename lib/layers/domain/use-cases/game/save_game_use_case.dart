import 'package:injectable/injectable.dart';

import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class SaveGameUseCase {
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const SaveGameUseCase({required this._sessionRepository, required this._saveRepository});

  void call() {
    _saveRepository.save(_sessionRepository.current());
  }
}
