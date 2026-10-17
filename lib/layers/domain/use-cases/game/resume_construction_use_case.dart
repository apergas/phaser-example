import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/resume_construction_result.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class ResumeConstructionUseCase {
  final GameSessionRepository _sessionRepository;

  const ResumeConstructionUseCase({required this._sessionRepository});

  ResumeConstructionResult call({required String buildingId}) {
    final world = _sessionRepository.current().world;
    final activity = world.player.activity;
    if (activity is WorkingActivityEntity && activity.intent == ConstructIntentEntity(buildingId: buildingId)) {
      return ResumeConstructionResult.ok;
    }
    return world.orderResumeConstruction(buildingId);
  }
}
