import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

void main() {
  test('testWhenSpendingAffordableWoodThenReturnsInventoryWithTheRest', () {
    // given
    final inventory = const InventoryEntity().addWood(6);

    // when
    final afterSpending = inventory.spendWood(4);

    // then
    expect(afterSpending?.wood, 2);
  });

  test('testWhenSpendingMoreWoodThanStoredThenReturnsNull', () {
    // given
    final inventory = const InventoryEntity().addWood(3);

    // when
    final afterSpending = inventory.spendWood(5);

    // then
    expect(afterSpending, isNull);
    expect(inventory.wood, 3);
  });

  test('testWhenAddingToolThenInventoryHasIt', () {
    // given
    const inventory = InventoryEntity();

    // when
    final withAxe = inventory.addTool(ToolKind.axe);

    // then
    expect(inventory.hasTool(ToolKind.axe), isFalse);
    expect(withAxe.hasTool(ToolKind.axe), isTrue);
  });

  test('testWhenAddingNegativeWoodThenFails', () {
    // given
    const inventory = InventoryEntity();

    // when / then
    expect(() => inventory.addWood(-1), throwsArgumentError);
  });
}
