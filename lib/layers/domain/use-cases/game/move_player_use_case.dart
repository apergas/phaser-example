import 'package:injectable/injectable.dart';

import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class MovePlayerUseCase {
  final GameSessionRepository _sessionRepository;

  const MovePlayerUseCase({required this._sessionRepository});

  void call({required double x, required double y}) {
    _sessionRepository.current().world.movePlayerTo(PositionEntity(x: x, y: y));
  }
}
