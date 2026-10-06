import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/world/funds_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenEarningGoldThenFundsHaveThatGold', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.tenGold);

    // then
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenEarningZeroThenFundsDoNotChange', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.zeroGold);

    // then
    expect(world.funds.resources.containsKey(Resource.gold), isFalse);
  });

  test('testWhenSpendingAffordableCostThenItIsSubtractedAndReturnsTrue', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.earn(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.fiveWoodAndFourGold);

    // then
    expect(paid, isTrue);
    expect(world.funds.amount(Resource.wood), 12);
    expect(world.funds.amount(Resource.gold), 6);
  });

  test('testWhenSpendingMoreThanFundsThenNothingChangesAndReturnsFalse', () {
    // given
    final world = WorldMock.make();
    world.earn(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.twentyGold);

    // then
    expect(paid, isFalse);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenEarningThenTheFundsAreThePlayerInventory', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.fourGold);

    // then
    expect(world.funds, world.player.inventory);
  });
}
