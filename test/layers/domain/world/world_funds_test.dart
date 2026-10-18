import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/world/extensions/stock_rules.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/world/funds_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenEarningGoldThenTheStockHasThatGold', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.tenGold);

    // then
    expect(world.stock.amount(Resource.gold), 10);
  });

  test('testWhenEarningZeroThenTheStockDoesNotChange', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.zeroGold);

    // then
    expect(world.stock.resources.containsKey(Resource.gold), isFalse);
  });

  test('testWhenEarningANegativeQuantityThenTheStockDoesNotChange', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.minusThreeGold);

    // then
    expect(world.stock.amount(Resource.gold), 0);
  });

  test('testWhenEarningThenTheFundsAreTheStockAndThePlayerGetsNothing', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.fourGold);

    // then
    expect(world.funds, world.stock);
    expect(world.player.inventory, InventoryEntityMock.mock);
  });

  test('testWhenSpendingAffordableCostThenItIsSubtractedFromTheStockAndReturnsTrue', () {
    // given
    final world = WorldMock.withStock(FundsMock.seventeenWood)..earn(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.fiveWoodAndFourGold);

    // then
    expect(paid, isTrue);
    expect(world.stock.amount(Resource.wood), 12);
    expect(world.stock.amount(Resource.gold), 6);
  });

  test('testWhenSpendingMoreThanTheStockThenNothingChangesAndReturnsFalse', () {
    // given
    final world = WorldMock.withStock(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.twentyGold);

    // then
    expect(paid, isFalse);
    expect(world.stock.amount(Resource.gold), 10);
  });

  test('testWhenSpendingWithOnlyPartOfTheCostThenNothingIsTakenAndReturnsFalse', () {
    // given
    final world = WorldMock.withStock(FundsMock.seventeenWood);

    // when
    final paid = world.spend(FundsMock.fiveWoodAndFourGold);

    // then
    expect(paid, isFalse);
    expect(world.stock.amount(Resource.wood), 17);
    expect(world.stock.amount(Resource.gold), 0);
  });

  test('testWhenThePlayerCarriesWoodThenItIsNotPartOfTheFunds', () {
    // given
    final world = WorldMock.make(player: PlayerEntityMock.withSeventeenWood);

    // when
    final paid = world.spend(FundsMock.fiveWoodAndFourGold);

    // then
    expect(paid, isFalse);
    expect(world.funds.amount(Resource.wood), 0);
    expect(world.player.inventory.amount(Resource.wood), 17);
  });
}
