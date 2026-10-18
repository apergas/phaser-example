import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';

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

  test('testWhenMeasuringTheLoadThenWoodAndStoneCountAndGoldAndManaDoNot', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final load = (inventory.load, inventory.freeLoad, inventory.isLoadFull);

    // then
    expect(load, (9, 1, false));
  });

  test('testWhenTheLoadReachesTheCapacityThenItIsFullWithNoFreeRoom', () {
    // given
    const inventory = InventoryEntityMock.fullOfWood;

    // when
    final load = (inventory.load, inventory.freeLoad, inventory.isLoadFull);

    // then
    expect(load, (10, 0, true));
  });

  test('testWhenTheLoadIsAboveTheCapacityThenTheFreeRoomIsNeverNegative', () {
    // given
    const inventory = InventoryEntityMock.overloaded;

    // when
    final freeLoad = inventory.freeLoad;

    // then
    expect((inventory.load, freeLoad, inventory.isLoadFull), (13, 0, true));
  });

  test('testWhenReadingTheCargoThenOnlyCarriedResourcesWithSomeAmountAppear', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final cargo = inventory.cargo;

    // then
    expect(cargo, InventoryEntityMock.woodAndStone);
    expect(InventoryEntityMock.onlyGoldAndMana.cargo, isEmpty);
  });

  test('testWhenReadingTheCargoForSomeResourcesThenOnlyThoseAppear', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final stone = inventory.cargoFor({Resource.stone});

    // then
    expect(stone, InventoryEntityMock.stoneOnly);
    expect(InventoryEntityMock.withWood.cargoFor({Resource.stone}), isEmpty);
  });

  test('testWhenAddingAnAmountsMapThenZeroAndNegativeQuantitiesAreSkipped', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final added = inventory.adding({Resource.wood: 4, Resource.stone: 0, Resource.gold: -2});

    // then
    expect(added, InventoryEntityMock.make(wood: 4));
  });

  test('testWhenUnloadingEverythingThenToolsGoldAndManaStay', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final unloaded = inventory.unloading({Resource.wood, Resource.stone});

    // then
    expect(unloaded, InventoryEntityMock.mixedLoadUnloaded);
  });

  test('testWhenUnloadingOnlyStoneThenTheWoodToolsGoldAndManaStay', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final unloaded = inventory.unloading({Resource.stone});

    // then
    expect(unloaded, InventoryEntityMock.mixedLoadWithoutStone);
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

  test('testWhenChangingResourcesOrToolsThenTheToolLevelsAreKept', () {
    // given
    const inventory = InventoryEntityMock.mixedLoad;

    // when
    final changed = [
      inventory.add(Resource.wood, 1),
      inventory.adding(InventoryEntityMock.tenWood),
      inventory.unloading({Resource.wood}),
      inventory.spend(InventoryEntityMock.twoWood)!,
      inventory.addTool(ToolKind.pickaxe),
    ];

    // then
    expect(changed.map((inventory) => inventory.toolLevel(ToolKind.axe)).toSet(), {2});
  });
}
