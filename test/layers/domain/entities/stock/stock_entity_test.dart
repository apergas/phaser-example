import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/stock/stock_entity_mock.dart';

void main() {
  test('testWhenComparingStocksWithTheSameResourcesThenTheyAreEqual', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final copy = StockEntityMock.make(wood: 6);

    // then
    expect(copy, stock);
    expect(copy.hashCode, stock.hashCode);
  });

  test('testWhenResourcesDifferThenStocksAreNotEqual', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final equal = stock == StockEntityMock.withStone;

    // then
    expect(equal, isFalse);
  });

  test('testWhenCopyingWithResourcesThenTheyAreReplaced', () {
    // given
    const stock = StockEntityMock.withWood;

    // when
    final copy = stock.copyWith(resources: StockEntityMock.withStone.resources);
    final same = stock.copyWith();

    // then
    expect(copy, StockEntityMock.withStone);
    expect(same, stock);
  });
}
