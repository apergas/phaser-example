import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/buy_gear_result.dart';
import '../../../../core/config/constants/enum/gear_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/gear.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class BuyGearUseCase {
  final GameSessionRepository _sessionRepository;

  const BuyGearUseCase({required this._sessionRepository});

  BuyGearResult call({required GearId id}) {
    final world = _sessionRepository.current().world;
    final gear = Gear.byId(id);
    if (!world.buildings.hasComplete(Gear.workshopFor(gear.slot))) return BuyGearResult.missingBuilding;
    if (world.hero.nextGear(gear.slot)?.id != id) return BuyGearResult.notNextTier;
    if (!world.spend(gear.cost)) return BuyGearResult.notEnoughResources;
    world.updateHero((hero) => hero.withGear(gear));
    return BuyGearResult.ok;
  }
}
