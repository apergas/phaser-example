import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_item_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_item_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveItemDBOMock.axe;

    // when
    final fromMap = SaveItemDBO.fromJson(dbo.toJson());
    final fromText = SaveItemDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveItemDBOMock.axe;

    // when
    final copy = SaveItemDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveItemDBOMock.axe;
    const others = [
      SaveItemDBOMock.withoutId,
      SaveItemDBOMock.unknownKind,
      SaveItemDBOMock.withoutX,
      SaveItemDBOMock.withoutY,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveItemDBOMock.axe;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveItemDBO.fromJson(json);

    // then
    expect(dbo, const SaveItemDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveItemDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveItemDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveItemDBOMock.axe;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveItemDBO('));
    expect(text, contains('id: axe-1'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SaveItemDBOMock.axe;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SaveItemDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
