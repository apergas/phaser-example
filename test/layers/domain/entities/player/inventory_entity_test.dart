import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenComparingInventoriesWithSameWoodAndToolsThenTheyAreEqual', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final copy = InventoryEntityMock.make(tools: {ToolKind.axe});

    // then
    expect(copy, inventory);
    expect(copy.hashCode, inventory.hashCode);
  });

  test('testWhenWoodOrToolsDifferThenInventoriesAreNotEqual', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final otherWood = inventory == InventoryEntityMock.withWood;
    final otherTools = inventory == InventoryEntityMock.withAxe;

    // then
    expect(otherWood, isFalse);
    expect(otherTools, isFalse);
  });

  test('testWhenCopyingWithWoodThenToolsAreKept', () {
    // given
    const inventory = InventoryEntityMock.withAxe;

    // when
    final copy = inventory.copyWith(resources: InventoryEntityMock.withWood.resources);

    // then
    expect(copy, InventoryEntityMock.make(wood: 6, tools: {ToolKind.axe}));
  });
}
