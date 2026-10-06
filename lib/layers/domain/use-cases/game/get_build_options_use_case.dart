import 'package:injectable/injectable.dart';

import '../../entities/game/build_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';
import '../../world/extensions/inventory_rules.dart';

@Injectable()
final class GetBuildOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetBuildOptionsUseCase({required this._sessionRepository});

  List<BuildOptionEntity> call() {
    final inventory = _sessionRepository.current().world.player.inventory;
    return Blueprints.all
        .map(
          (blueprint) => BuildOptionEntity(
            blueprint: blueprint.id,
            cost: blueprint.cost,
            missing: inventory.missing(blueprint.cost),
          ),
        )
        .toList();
  }
}
