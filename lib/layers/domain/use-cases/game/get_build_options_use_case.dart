import 'package:injectable/injectable.dart';

import '../../entities/game/build_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';
import '../../world/extensions/stock_rules.dart';

@Injectable()
final class GetBuildOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetBuildOptionsUseCase({required this._sessionRepository});

  List<BuildOptionEntity> call() {
    final funds = _sessionRepository.current().world.funds;
    return Blueprints.all
        .where((blueprint) => blueprint.isBuildable)
        .map(
          (blueprint) => BuildOptionEntity(
            blueprint: blueprint.id,
            cost: blueprint.cost,
            missing: funds.missing(blueprint.cost),
          ),
        )
        .toList();
  }
}
