import 'package:injectable/injectable.dart';

import '../../entities/game/build_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';
import '../../world/extensions/blueprint_rules.dart';

@Injectable()
final class GetBuildOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetBuildOptionsUseCase({required this._sessionRepository});

  List<BuildOptionEntity> call() {
    final wood = _sessionRepository.current().world.player.inventory.wood;
    return Blueprints.all
        .map(
          (blueprint) => BuildOptionEntity(
            blueprint: blueprint.id,
            woodCost: blueprint.woodCost,
            isAffordable: blueprint.isAffordableWith(wood),
          ),
        )
        .toList();
  }
}
