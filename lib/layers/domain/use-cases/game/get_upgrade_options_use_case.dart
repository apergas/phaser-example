import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/upgrade_option_state.dart';
import '../../entities/upgrade/upgrade_entity.dart';
import '../../entities/upgrade/upgrade_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/upgrades.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetUpgradeOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetUpgradeOptionsUseCase({required this._sessionRepository});

  List<UpgradeOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [for (final upgrade in Upgrades.all) _option(world, upgrade)];
  }

  UpgradeOptionEntity _option(World world, UpgradeEntity upgrade) {
    if (world.player.inventory.toolLevel(upgrade.tool) >= upgrade.level) {
      return UpgradeOptionEntity(upgrade: upgrade, state: UpgradeOptionState.owned);
    }
    final missing = world.funds.missing(upgrade.cost);
    final UpgradeOptionState state;
    if (!world.buildings.hasComplete(Upgrades.building)) {
      state = UpgradeOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = UpgradeOptionState.unaffordable;
    } else {
      state = UpgradeOptionState.available;
    }
    return UpgradeOptionEntity(upgrade: upgrade, state: state, missing: missing);
  }
}
