import 'package:injectable/injectable.dart';

import '../../entities/game/game_event_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class AdvanceGameUseCase {
  final GameSessionRepository _sessionRepository;

  const AdvanceGameUseCase({required this._sessionRepository});

  List<GameEventEntity> call({required double deltaMs}) {
    final session = _sessionRepository.current();
    final worldEvents = session.world.advance(deltaMs);
    return [...worldEvents, ...session.quests.update(session.world)];
  }
}
