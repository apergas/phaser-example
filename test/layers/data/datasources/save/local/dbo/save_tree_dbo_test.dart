import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_tree_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_tree_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;

    // when
    final fromMap = SaveTreeDBO.fromJson(dbo.toJson());
    final fromText = SaveTreeDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;

    // when
    final copy = SaveTreeDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;
    const others = [
      SaveTreeDBOMock.withoutHits,
      SaveTreeDBOMock.unknownKind,
      SaveTreeDBOMock.withoutX,
      SaveTreeDBOMock.withoutY,
      SaveTreeDBOMock.withoutId,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveTreeDBO.fromJson(json);

    // then
    expect(dbo, const SaveTreeDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [SaveTreeDBOMock.wrongTypes, SaveTreeDBOMock.wrongHitsType, SaveTreeDBOMock.wrongCoordinateType];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveTreeDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveTreeDBO('));
    expect(text, contains('id: tree-1'));
  });

  test('testWhenTheCoordinatesAreWholeNumbersThenTheyAreReadAsDoubles', () {
    // given
    const dbo = SaveTreeDBOMock.withThreeHitsTaken;
    final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
    json['x'] = 5;
    json['y'] = 6;

    // when
    final read = SaveTreeDBO.fromJson(json);

    // then
    expect(read.x, 5.0);
    expect(read.y, 6.0);
    expect(read.x, isA<double>());
  });
}
