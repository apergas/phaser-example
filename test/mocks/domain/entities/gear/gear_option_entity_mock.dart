import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/gear/gear_option_entity.dart';
import 'package:rpg/layers/domain/rules/gear.dart';

abstract final class GearOptionEntityMock {
  static GearOptionEntity equipped(GearId id) => GearOptionEntity(gear: Gear.byId(id), state: GearOptionState.equipped);

  static GearOptionEntity make(GearId id, GearOptionState state, {Map<Resource, int>? missing}) {
    final gear = Gear.byId(id);
    return GearOptionEntity(gear: gear, state: state, missing: missing ?? gear.cost);
  }

  static GearOptionEntity get shortSwordAvailable => make(GearId.shortSword, GearOptionState.available, missing: {});

  static GearOptionEntity get shortSwordFiveGoldShort =>
      make(GearId.shortSword, GearOptionState.unaffordable, missing: {Resource.gold: 5});

  static List<GearOptionEntity> get newHeroWithoutWorkshops => [
    equipped(GearId.woodcutterAxe),
    make(GearId.shortSword, GearOptionState.needsBuilding),
    make(GearId.ironSword, GearOptionState.locked),
    make(GearId.steelSword, GearOptionState.locked),
    equipped(GearId.workClothes),
    make(GearId.leatherArmor, GearOptionState.needsBuilding),
    make(GearId.chainMail, GearOptionState.locked),
    make(GearId.plateArmor, GearOptionState.locked),
  ];

  static List<GearOptionEntity> get fullyGeared => [equipped(GearId.steelSword), equipped(GearId.plateArmor)];
}
