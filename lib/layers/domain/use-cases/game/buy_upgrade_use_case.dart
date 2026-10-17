import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../../core/config/constants/enum/upgrade_result.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/upgrades.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/extensions/player_rules.dart';

@Injectable()
final class BuyUpgradeUseCase {
  final GameSessionRepository _sessionRepository;

  const BuyUpgradeUseCase({required this._sessionRepository});

  UpgradeResult call({required UpgradeId id}) {
    final world = _sessionRepository.current().world;
    final upgrade = Upgrades.of(id);
    if (world.player.inventory.toolLevel(upgrade.tool) >= upgrade.level) return UpgradeResult.alreadyOwned;
    if (!world.buildings.hasComplete(Upgrades.building)) return UpgradeResult.noWorkshop;
    if (!world.spend(upgrade.cost)) return UpgradeResult.notEnoughResources;
    world.updatePlayer(
      (player) => player.withInventory(player.inventory.withToolLevel(upgrade.tool, upgrade.level)),
    );
    return UpgradeResult.ok;
  }
}
