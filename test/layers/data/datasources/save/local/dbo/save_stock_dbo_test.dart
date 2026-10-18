import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_stock_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_stock_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveStockDBOMock.stock;

    // when
    final fromMap = SaveStockDBO.fromJson(dbo.toJson());
    final fromText = SaveStockDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
    expect(dbo.hashCode, fromMap.hashCode);
  });

  test('testWhenReadingAVersionOneStockThenItsEmptyToolsAreIgnored', () {
    // given
    const json = SaveStockDBOMock.versionOneJson;

    // when
    final dbo = SaveStockDBO.fromJson(json);

    // then
    expect(dbo, SaveStockDBOMock.stock);
  });

  test('testWhenTheResourcesDifferThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveStockDBOMock.stock;
    const others = [SaveStockDBOMock.empty, SaveStockDBOMock.withZeroResource, SaveStockDBOMock.withTheVersionOneLoad];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
    expect(dbo == Object(), isFalse);
  });

  test('testWhenTheJsonIsEmptyThenTheResourcesAreNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveStockDBO.fromJson(json);

    // then
    expect(dbo, SaveStockDBOMock.empty);
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const json = SaveStockDBOMock.wrongTypes;

    // when
    void read() => SaveStockDBO.fromJson(json);

    // then
    expect(read, throwsA(isA<TypeError>()));
  });

  test('testWhenPrintingTheDboThenItListsItsResources', () {
    // given
    const dbo = SaveStockDBOMock.onlyTheVersionOneLoad;

    // when
    final text = dbo.toString();

    // then
    expect(text, 'SaveStockDBO(resources: {wood: 4, stone: 3})');
  });
}
