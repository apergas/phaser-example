import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/game/construction_result_entity.dart';
import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';

@Injectable()
final class ConstructBuildingUseCase {
  final GameSessionRepository _sessionRepository;

  const ConstructBuildingUseCase({required this._sessionRepository});

  ConstructionResultEntity call({required BlueprintId blueprint, required double x, required double y}) {
    return _sessionRepository.current().world.orderConstruction(Blueprints.of(blueprint), PositionEntity(x: x, y: y));
  }
}
