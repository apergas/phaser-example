import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_inventory_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveInventoryDBOMock.player;

    // when
    final fromMap = SaveInventoryDBO.fromJson(dbo.toJson());
    final fromText = SaveInventoryDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveInventoryDBOMock.player;

    // when
    final copy = SaveInventoryDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveInventoryDBOMock.player;
    const others = [
      SaveInventoryDBOMock.versionOnePlayer,
      SaveInventoryDBOMock.empty,
      SaveInventoryDBOMock.withUnknownTool,
      SaveInventoryDBOMock.withToolLevelZero,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveInventoryDBOMock.player;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveInventoryDBO.fromJson(json);

    // then
    expect(dbo, const SaveInventoryDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [
      SaveInventoryDBOMock.wrongTypes,
      SaveInventoryDBOMock.wrongListType,
      SaveInventoryDBOMock.wrongToolListItem,
    ];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveInventoryDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveInventoryDBOMock.player;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveInventoryDBO('));
    expect(text, contains('tools: [axe, pickaxe]'));
  });
}
