import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_decoration_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_decoration_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;

    // when
    final fromMap = SaveDecorationDBO.fromJson(dbo.toJson());
    final fromText = SaveDecorationDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;

    // when
    final copy = SaveDecorationDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;
    const others = [
      SaveDecorationDBOMock.withoutId,
      SaveDecorationDBOMock.unknownKind,
      SaveDecorationDBOMock.withoutX,
      SaveDecorationDBOMock.withoutY,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveDecorationDBO.fromJson(json);

    // then
    expect(dbo, const SaveDecorationDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveDecorationDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveDecorationDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveDecorationDBO('));
    expect(text, contains('id: decoration-1'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SaveDecorationDBOMock.rock;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SaveDecorationDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
