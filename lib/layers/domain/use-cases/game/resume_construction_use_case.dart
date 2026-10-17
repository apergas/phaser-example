import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/resume_construction_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class ResumeConstructionUseCase {
  final GameSessionRepository _sessionRepository;

  const ResumeConstructionUseCase({required this._sessionRepository});

  ResumeConstructionResult call({required String buildingId}) =>
      _sessionRepository.current().world.orderResumeConstruction(buildingId);
}
