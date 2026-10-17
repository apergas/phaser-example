import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/mine_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class MineRockUseCase {
  final GameSessionRepository _sessionRepository;

  const MineRockUseCase({required this._sessionRepository});

  MineResult call({required String rockId}) => _sessionRepository.current().world.orderMine(rockId);
}
