import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/domain/rules/upgrades.dart';

import '../../../mocks/domain/entities/upgrade/upgrade_entity_mock.dart';

void main() {
  test('testWhenListingUpgradesThenTheIronAxeAndTheIronPickaxeCostWoodAndStone', () {
    // given
    const upgrades = Upgrades.all;

    // when
    final ids = upgrades.map((upgrade) => upgrade.id);

    // then
    expect(upgrades, [UpgradeEntityMock.ironAxe, UpgradeEntityMock.ironPickaxe]);
    expect(ids.toSet(), UpgradeId.values.toSet());
  });

  test('testWhenFindingAnUpgradeByIdThenItReturnsThatUpgrade', () {
    // given
    const id = UpgradeId.ironPickaxe;

    // when
    final upgrade = Upgrades.of(id);

    // then
    expect(upgrade, UpgradeEntityMock.ironPickaxe);
  });

  test('testWhenAskingWhichUpgradeALevelReachesThenItIsTheLastOneAtOrBelowIt', () {
    // given
    const tool = ToolKind.axe;

    // when
    final reached = [Upgrades.reached(tool, 1), Upgrades.reached(tool, 2), Upgrades.reached(tool, 5)];

    // then
    expect(reached, [null, UpgradeEntityMock.ironAxe, UpgradeEntityMock.ironAxe]);
  });

  test('testWhenAskingForTheMaxLevelThenBothToolsReachLevelTwo', () {
    // given
    const tools = ToolKind.values;

    // when
    final levels = tools.map(Upgrades.maxLevel).toList();

    // then
    expect(levels, [2, 2]);
  });

  test('testWhenAskingWhereUpgradesAreBoughtThenItIsTheWorkshop', () {
    // given
    const expected = BlueprintId.workshop;

    // when
    const building = Upgrades.building;

    // then
    expect(building, expected);
  });
}
