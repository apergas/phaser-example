import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenComparingInventoriesWithTheSameToolsThenTheyAreEqual', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final copy = InventoryEntityMock.make(tools: {ToolKind.axe});

    // then
    expect(copy, inventory);
    expect(copy.hashCode, inventory.hashCode);
  });

  test('testWhenToolsDifferThenInventoriesAreNotEqual', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final otherTools = inventory == InventoryEntityMock.withAxe;

    // then
    expect(otherTools, isFalse);
  });

  test('testWhenCopyingWithToolsThenTheToolLevelsAreKept', () {
    // given
    const inventory = InventoryEntityMock.withIronAxe;

    // when
    final copy = inventory.copyWith(tools: InventoryEntityMock.withBothToolsAndIronAxe.tools);

    // then
    expect(copy, InventoryEntityMock.withBothToolsAndIronAxe);
  });

  test('testWhenToolLevelsDifferThenInventoriesAreNotEqual', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final equal = inventory == InventoryEntityMock.withIronAxe;
    final copy = inventory.copyWith(toolLevels: InventoryEntityMock.withIronAxe.toolLevels);

    // then
    expect(equal, isFalse);
    expect(copy, InventoryEntityMock.withIronAxe);
    expect(copy.hashCode, InventoryEntityMock.withIronAxe.hashCode);
  });
}
