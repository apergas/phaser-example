import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/upgrade_option_state.dart';
import 'package:farming/layers/domain/entities/upgrade/upgrade_option_entity.dart';

import 'upgrade_entity_mock.dart';

abstract final class UpgradeOptionEntityMock {
  static const UpgradeOptionEntity ironAxeAvailable = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironAxe,
    state: UpgradeOptionState.available,
  );

  static const UpgradeOptionEntity ironAxeOwned = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironAxe,
    state: UpgradeOptionState.owned,
  );

  static const UpgradeOptionEntity ironAxeWithoutWorkshop = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironAxe,
    state: UpgradeOptionState.needsBuilding,
    missing: {Resource.wood: 15, Resource.stone: 15},
  );

  static const UpgradeOptionEntity ironPickaxeWithoutWorkshop = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironPickaxe,
    state: UpgradeOptionState.needsBuilding,
    missing: {Resource.wood: 10, Resource.stone: 20},
  );

  static const UpgradeOptionEntity ironAxeFiveStoneShort = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironAxe,
    state: UpgradeOptionState.unaffordable,
    missing: {Resource.stone: 5},
  );

  static const UpgradeOptionEntity ironPickaxeAvailable = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironPickaxe,
    state: UpgradeOptionState.available,
  );

  static const UpgradeOptionEntity ironPickaxeTenStoneShort = UpgradeOptionEntity(
    upgrade: UpgradeEntityMock.ironPickaxe,
    state: UpgradeOptionState.unaffordable,
    missing: {Resource.stone: 10},
  );
}
