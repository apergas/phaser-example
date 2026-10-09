import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/gear_option_state.dart';
import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../entities/gear/gear_entity.dart';
import '../../entities/gear/gear_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/gear.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetGearOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetGearOptionsUseCase({required this._sessionRepository});

  List<GearOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [
      for (final slot in GearSlot.values)
        for (var tier = world.hero.tierOf(slot); tier <= Gear.maxTier(slot); tier++)
          _option(world, Gear.of(slot, tier)),
    ];
  }

  GearOptionEntity _option(World world, GearEntity gear) {
    final equippedTier = world.hero.tierOf(gear.slot);
    if (gear.tier == equippedTier) return GearOptionEntity(gear: gear, state: GearOptionState.equipped);
    final missing = world.funds.missing(gear.cost);
    final GearOptionState state;
    if (gear.tier > equippedTier + 1) {
      state = GearOptionState.locked;
    } else if (!world.buildings.hasComplete(Gear.workshopFor(gear.slot))) {
      state = GearOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = GearOptionState.unaffordable;
    } else {
      state = GearOptionState.available;
    }
    return GearOptionEntity(gear: gear, state: state, missing: missing);
  }
}
