import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';

@Injectable()
final class CanPlaceBuildingUseCase {
  final GameSessionRepository _sessionRepository;

  const CanPlaceBuildingUseCase({required this._sessionRepository});

  bool call({required BlueprintId blueprint, required double x, required double y}) {
    return _sessionRepository.current().world.canPlace(Blueprints.of(blueprint), PositionEntity(x: x, y: y));
  }
}
