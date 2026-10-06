import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenAddingResourcesThenAmountAccumulates', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final updated = inventory.add(Resource.wood, 4).add(Resource.wood, 2);

    // then
    expect(inventory.amount(Resource.wood), 0);
    expect(updated.amount(Resource.wood), 6);
  });

  test('testWhenSpendingAnAffordableCostThenReturnsInventoryWithTheRest', () {
    // given
    const inventory = InventoryEntityMock.withWood;

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fourWood);

    // then
    expect(afterSpending?.amount(Resource.wood), 2);
  });

  test('testWhenSpendingMoreThanStoredThenReturnsNullAndReportsWhatIsMissing', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 3);

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fiveWood);
    final missing = inventory.missing(InventoryEntityMock.fiveWood);

    // then
    expect(afterSpending, isNull);
    expect(missing, InventoryEntityMock.twoWood);
    expect(inventory.amount(Resource.wood), 3);
  });

  test('testWhenNothingIsMissingThenMissingIsEmpty', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 15);

    // when
    final missing = inventory.missing(InventoryEntityMock.fifteenWood);

    // then
    expect(missing, isEmpty);
  });

  test('testWhenSpendingEverythingThenTheResourceDisappearsFromTheMap', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 15);

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fifteenWood);

    // then
    expect(afterSpending, InventoryEntityMock.mock);
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

  test('testWhenAddingZeroThenReturnsTheSameInventory', () {
    // given
    const inventory = InventoryEntityMock.withWood;

    // when
    final updated = inventory.add(Resource.wood, 0);

    // then
    expect(identical(updated, inventory), isTrue);
  });

  test('testWhenSpendingAZeroQuantityCostThenInventoryIsUnchanged', () {
    // given
    const inventory = InventoryEntityMock.withWood;

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.zeroWood);

    // then
    expect(afterSpending, inventory);
  });

  test('testWhenACostHasANegativeQuantityThenMissingAndSpendFail', () {
    // given
    const inventory = InventoryEntityMock.withWood;

    // when
    Object missing() => inventory.missing(InventoryEntityMock.negativeWood);
    Object spend() => inventory.spend(InventoryEntityMock.negativeWood)!;

    // then
    expect(missing, throwsArgumentError);
    expect(spend, throwsArgumentError);
  });

  test('testWhenAddingANegativeAmountThenFails', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    Object act() => inventory.add(Resource.wood, -1);

    // then
    expect(act, throwsArgumentError);
  });
}
