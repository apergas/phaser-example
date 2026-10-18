import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_player_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_player_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SavePlayerDBOMock.mock;

    // when
    final fromMap = SavePlayerDBO.fromJson(dbo.toJson());
    final fromText = SavePlayerDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SavePlayerDBOMock.mock;

    // when
    final copy = SavePlayerDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SavePlayerDBOMock.mock;
    const others = [SavePlayerDBOMock.withoutInventory, SavePlayerDBOMock.withoutX, SavePlayerDBOMock.withoutY];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SavePlayerDBOMock.mock;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SavePlayerDBO.fromJson(json);

    // then
    expect(dbo, const SavePlayerDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SavePlayerDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SavePlayerDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SavePlayerDBOMock.mock;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SavePlayerDBO('));
    expect(text, contains('x: ${420.0}'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SavePlayerDBOMock.mock;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SavePlayerDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
