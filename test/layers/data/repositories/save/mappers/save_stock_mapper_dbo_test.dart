import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_stock_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_inventory_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SaveStockMapperDBO sut;

  setUp(() {
    sut = SaveStockMapperDBO();
  });

  test('testWhenMappingTheStockToDboThenEveryResourceKeepsItsName', () {
    // given
    const stock = SaveScenarioMock.stock;

    // when
    final dbo = sut.toDBO(stock);

    // then
    expect(dbo, SaveInventoryDBOMock.stock);
  });

  test('testWhenMappingTheDboToTheStockThenEveryResourceComesBack', () {
    // given
    const dbo = SaveInventoryDBOMock.stock;

    // when
    final stock = sut.toEntity(dbo);

    // then
    expect(stock, SaveScenarioMock.stock);
  });

  test('testWhenThereIsNoDboThenTheStockIsEmpty', () {
    // given
    const SaveInventoryDBO? dbo = null;

    // when
    final stock = sut.toEntity(dbo);

    // then
    expect(stock, StockEntityMock.mock);
  });

  test('testWhenTheDboHasNoFieldsThenTheStockIsEmpty', () {
    // given
    const dbo = SaveInventoryDBOMock.empty;

    // when
    final stock = sut.toEntity(dbo);

    // then
    expect(stock, StockEntityMock.mock);
  });

  test('testWhenAResourceIsZeroThenItDoesNotAppearInTheStock', () {
    // given
    const dbo = SaveInventoryDBOMock.withZeroResource;

    // when
    final stock = sut.toEntity(dbo);

    // then
    expect(stock, StockEntityMock.withStone);
  });

  test('testWhenAResourceIsUnknownThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withUnknownResource;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stock: unknown resource "diamond"'));
  });

  test('testWhenAnAmountIsNegativeThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withNegativeResource;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('stock: -1 wood'));
  });
}
