import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final fromMap = SaveDBO.fromJson(dbo.toJson());
    final fromText = SaveDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
    expect(fromText.hashCode, dbo.hashCode);
  });

  test('testWhenThePiecesAreSavedThenToJsonNestsThemAsMapsAndLists', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final json = dbo.toJson();

    // then
    expect(json['version'], SaveDBO.currentVersion);
    expect(json['player'], isA<Map<String, dynamic>>());
    expect(json['trees'], isA<List<Map<String, dynamic>>>());
    expect((json['trees'] as List).length, 2);
    expect(json['idCounters'], {'building': 3});
    expect(json['completedQuests'], ['gatherWood', 'buildHouse', 'buildForge']);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final copy = SaveDBOMock.sameAsEverything;

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    final dbo = SaveDBOMock.everything;
    final others = [
      SaveDBOMock.otherVersion,
      SaveDBOMock.withoutVersion,
      SaveDBOMock.withoutWidth,
      SaveDBOMock.withoutHeight,
      SaveDBOMock.withoutPlayer,
      SaveDBOMock.withOtherTrees,
      SaveDBOMock.withOtherCounters,
      SaveDBOMock.withOtherQuests,
      SaveDBOMock.withNothingElse,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveDBO.fromJson(json);

    // then
    expect(dbo, const SaveDBO());
  });

  test('testWhenTheOptionalPiecesAreMissingThenTheyStayNull', () {
    // given
    final json = SaveDBOMock.onlyWorldSize.toJson();

    // when
    final dbo = SaveDBO.fromJson(json);

    // then
    expect(dbo.hero, isNull);
    expect(dbo.stats, isNull);
    expect(dbo.stock, isNull);
    expect(dbo.trees, isNull);
    expect(dbo.buildings, isNull);
    expect(dbo.completedQuests, isNull);
    expect(dbo, SaveDBOMock.onlyWorldSize);
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [
      SaveDBOMock.wrongTypes,
      SaveDBOMock.wrongTreesType,
      SaveDBOMock.wrongTreeItemType,
      SaveDBOMock.wrongPlayerType,
      SaveDBOMock.wrongIdCountersType,
      SaveDBOMock.wrongQuestsType,
    ];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveDBO(version: 3, width: ${1600.0}, height: ${1200.0}'));
    expect(text, contains('idCounters: {building: 3}'));
  });
}
