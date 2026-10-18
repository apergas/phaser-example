import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_stump_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_stump_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;

    // when
    final fromMap = SaveStumpDBO.fromJson(dbo.toJson());
    final fromText = SaveStumpDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;

    // when
    final copy = SaveStumpDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;
    const others = [
      SaveStumpDBOMock.fresh,
      SaveStumpDBOMock.withoutId,
      SaveStumpDBOMock.unknownKind,
      SaveStumpDBOMock.withoutX,
      SaveStumpDBOMock.withoutY,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveStumpDBO.fromJson(json);

    // then
    expect(dbo, const SaveStumpDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveStumpDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveStumpDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveStumpDBO('));
    expect(text, contains('id: tree-1'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SaveStumpDBOMock.almostSapling;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SaveStumpDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
