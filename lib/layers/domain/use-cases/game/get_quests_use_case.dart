import 'package:injectable/injectable.dart';

import '../../entities/game/quest_progress_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetQuestsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetQuestsUseCase({required this._sessionRepository});

  List<QuestProgressEntity> call() {
    final session = _sessionRepository.current();
    return session.quests.status(session.world);
  }
}
