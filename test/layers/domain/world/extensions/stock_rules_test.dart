import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/world/extensions/stock_rules.dart';

import '../../../../mocks/domain/entities/stock/stock_entity_mock.dart';

void main() {
  test('testWhenAddingResourcesThenAmountAccumulates', () {
    // given
    const stock = StockEntityMock.mock;

    // when
    final updated = stock.add(Resource.wood, 4).add(Resource.wood, 2);

    // then
    expect(stock.amount(Resource.wood), 0);
    expect(updated.amount(Resource.wood), 6);
  });

  test('testWhenAddingZeroThenReturnsTheSameStock', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final updated = stock.add(Resource.wood, 0);

    // then
    expect(identical(updated, stock), isTrue);
  });

  test('testWhenAddingANegativeAmountThenFails', () {
    // given
    const stock = StockEntityMock.mock;

    // when
    Object act() => stock.add(Resource.wood, -1);

    // then
    expect(act, throwsArgumentError);
  });

  test('testWhenAddingAnAmountsMapThenZeroAndNegativeQuantitiesAreSkipped', () {
    // given
    const stock = StockEntityMock.mock;

    // when
    final added = stock.adding(StockEntityMock.woodZeroStoneAndNegativeGold);

    // then
    expect(added, StockEntityMock.make(wood: 4));
  });

  test('testWhenSpendingAnAffordableCostThenReturnsTheStockWithTheRest', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final afterSpending = stock.spend(StockEntityMock.fourWood);

    // then
    expect(afterSpending?.amount(Resource.wood), 2);
  });

  test('testWhenSpendingMoreThanStoredThenReturnsNullAndReportsWhatIsMissing', () {
    // given
    final stock = StockEntityMock.make(wood: 3);

    // when
    final afterSpending = stock.spend(StockEntityMock.fiveWood);
    final missing = stock.missing(StockEntityMock.fiveWood);

    // then
    expect(afterSpending, isNull);
    expect(missing, StockEntityMock.twoWood);
    expect(stock.amount(Resource.wood), 3);
  });

  test('testWhenNothingIsMissingThenMissingIsEmpty', () {
    // given
    final stock = StockEntityMock.make(wood: 15);

    // when
    final missing = stock.missing(StockEntityMock.fifteenWood);

    // then
    expect(missing, isEmpty);
  });

  test('testWhenSpendingEverythingThenTheResourceDisappearsFromTheMap', () {
    // given
    final stock = StockEntityMock.make(wood: 15);

    // when
    final afterSpending = stock.spend(StockEntityMock.fifteenWood);

    // then
    expect(afterSpending, StockEntityMock.mock);
  });

  test('testWhenSpendingAZeroQuantityCostThenTheStockIsUnchanged', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final afterSpending = stock.spend(StockEntityMock.zeroWood);

    // then
    expect(afterSpending, stock);
  });

  test('testWhenACostHasANegativeQuantityThenMissingAndSpendFail', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    Object missing() => stock.missing(StockEntityMock.negativeWood);
    Object spend() => stock.spend(StockEntityMock.negativeWood)!;

    // then
    expect(missing, throwsArgumentError);
    expect(spend, throwsArgumentError);
  });
}
