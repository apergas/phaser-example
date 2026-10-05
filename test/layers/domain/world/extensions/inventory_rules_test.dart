import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

void main() {
  test('testWhenSpendingAffordableWoodThenReturnsInventoryWithTheRest', () {
    // given
    final inventory = InventoryEntityMock.mock.addWood(6);

    // when
    final afterSpending = inventory.spendWood(4);

    // then
    expect(afterSpending?.wood, 2);
  });

  test('testWhenSpendingMoreWoodThanStoredThenReturnsNull', () {
    // given
    final inventory = InventoryEntityMock.mock.addWood(3);

    // when
    final afterSpending = inventory.spendWood(5);

    // then
    expect(afterSpending, isNull);
    expect(inventory.wood, 3);
  });

  test('testWhenAddingToolThenInventoryHasIt', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final withAxe = inventory.addTool(ToolKind.axe);

    // then
    expect(inventory.hasTool(ToolKind.axe), isFalse);
    expect(withAxe.hasTool(ToolKind.axe), isTrue);
  });

  test('testWhenAddingNegativeWoodThenFails', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    Object act() => inventory.addWood(-1);

    // then
    expect(act, throwsArgumentError);
  });
}
