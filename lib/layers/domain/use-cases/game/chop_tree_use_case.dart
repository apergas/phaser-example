import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/chop_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class ChopTreeUseCase {
  final GameSessionRepository _sessionRepository;

  const ChopTreeUseCase({required this._sessionRepository});

  ChopResult call({required String treeId}) => _sessionRepository.current().world.orderChop(treeId);
}
