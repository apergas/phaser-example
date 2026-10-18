import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenAddingToolThenInventoryHasIt', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final withAxe = inventory.addTool(ToolKind.axe);

    // then
    expect(inventory.hasTool(ToolKind.axe), isFalse);
    expect(withAxe.hasTool(ToolKind.axe), isTrue);
  });

  test('testWhenAToolWasNeverUpgradedThenItsLevelIsOne', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final levels = (inventory.toolLevel(ToolKind.axe), inventory.toolLevel(ToolKind.pickaxe));

    // then
    expect(levels, (1, 1));
  });

  test('testWhenSettingAToolLevelThenOnlyTheLevelChanges', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final upgraded = inventory.withToolLevel(ToolKind.axe, 2);

    // then
    expect(upgraded, InventoryEntityMock.withIronAxe);
  });

  test('testWhenSettingAToolLevelBelowOneThenFails', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    void zero() => inventory.withToolLevel(ToolKind.axe, 0);

    // then
    expect(zero, throwsArgumentError);
  });

  test('testWhenTheToolIsAtLevelOneThenTheHitsNeededAreTheSame', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final hits = [for (var base = 1; base <= 9; base++) inventory.hitsNeeded(ToolKind.axe, base)];

    // then
    expect(hits, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });

  test('testWhenTheToolIsAtLevelTwoThenItNeedsFortyPercentFewerHitsRoundedUp', () {
    // given
    const inventory = InventoryEntityMock.withIronAxe;

    // when
    final hits = [for (var base = 1; base <= 9; base++) inventory.hitsNeeded(ToolKind.axe, base)];

    // then
    expect(hits, [1, 2, 2, 3, 3, 4, 5, 5, 6]);
    expect(inventory.hitsNeeded(ToolKind.pickaxe, 8), 8);
  });

  test('testWhenAddingAToolThenTheToolLevelsAreKept', () {
    // given
    const inventory = InventoryEntityMock.withIronAxe;

    // when
    final changed = inventory.addTool(ToolKind.pickaxe);

    // then
    expect(changed, InventoryEntityMock.withBothToolsAndIronAxe);
  });
}
