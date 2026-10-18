import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_stats_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_stats_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveStatsDBOMock.mock;

    // when
    final fromMap = SaveStatsDBO.fromJson(dbo.toJson());
    final fromText = SaveStatsDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveStatsDBOMock.mock;

    // when
    final copy = SaveStatsDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveStatsDBOMock.mock;
    const others = [
      SaveStatsDBOMock.empty,
      SaveStatsDBOMock.negativeTreesFelled,
      SaveStatsDBOMock.unknownKind,
      SaveStatsDBOMock.negativeBuildings,
      SaveStatsDBOMock.negativeRegrown,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveStatsDBOMock.mock;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveStatsDBO.fromJson(json);

    // then
    expect(dbo, const SaveStatsDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveStatsDBOMock.wrongTypes];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveStatsDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveStatsDBOMock.mock;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveStatsDBO('));
    expect(text, contains('treesFelled: 4'));
  });
}
