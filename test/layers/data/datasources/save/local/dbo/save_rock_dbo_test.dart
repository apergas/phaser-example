import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_rock_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_rock_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;

    // when
    final fromMap = SaveRockDBO.fromJson(dbo.toJson());
    final fromText = SaveRockDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;

    // when
    final copy = SaveRockDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;
    const others = [
      SaveRockDBOMock.intact,
      SaveRockDBOMock.withoutId,
      SaveRockDBOMock.withoutX,
      SaveRockDBOMock.withoutY,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveRockDBO.fromJson(json);

    // then
    expect(dbo, const SaveRockDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveRockDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveRockDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveRockDBO('));
    expect(text, contains('id: rock-1'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SaveRockDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
