import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_hero_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_hero_dbo_mock.dart';

void main() {
  test('testWhenReadingWhatToJsonWroteThenTheDboIsTheSame', () {
    // given
    const dbo = SaveHeroDBOMock.mock;

    // when
    final fromMap = SaveHeroDBO.fromJson(dbo.toJson());
    final fromText = SaveHeroDBO.fromJson(jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>);

    // then
    expect(fromMap, dbo);
    expect(fromText, dbo);
  });

  test('testWhenTwoDbosHaveTheSameFieldsThenTheyAreEqualAndShareTheHash', () {
    // given
    const dbo = SaveHeroDBOMock.mock;

    // when
    final copy = SaveHeroDBO.fromJson(dbo.toJson());

    // then
    expect(copy, isNot(same(dbo)));
    expect(copy, dbo);
    expect(copy.hashCode, dbo.hashCode);
  });

  test('testWhenAFieldDiffersThenTheDbosAreNotEqual', () {
    // given
    const dbo = SaveHeroDBOMock.mock;
    const others = [
      SaveHeroDBOMock.empty,
      SaveHeroDBOMock.weaponTierTooHigh,
      SaveHeroDBOMock.armorTierTooHigh,
      SaveHeroDBOMock.unknownSkill,
      SaveHeroDBOMock.unknownLevel,
      SaveHeroDBOMock.negativeFights,
    ];

    // when
    final equalOnes = others.where((other) => other == dbo);

    // then
    expect(equalOnes, isEmpty);
  });

  test('testWhenComparingWithAnotherTypeThenTheDboIsNotEqual', () {
    // given
    const dbo = SaveHeroDBOMock.mock;

    // when
    final isEqual = dbo == Object();

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenTheJsonIsEmptyThenEveryFieldIsNull', () {
    // given
    const json = <String, dynamic>{};

    // when
    final dbo = SaveHeroDBO.fromJson(json);

    // then
    expect(dbo, const SaveHeroDBO());
  });

  test('testWhenAJsonValueHasTheWrongTypeThenFromJsonThrows', () {
    // given
    const wrongJsons = [
      SaveHeroDBOMock.wrongTypes,
      SaveHeroDBOMock.wrongSkillLevelType,
      SaveHeroDBOMock.wrongClearedLevelsType,
    ];

    // when
    final attempts = [for (final json in wrongJsons) () => SaveHeroDBO.fromJson(json)];

    // then
    for (final attempt in attempts) {
      expect(attempt, throwsA(isA<TypeError>()));
    }
  });

  test('testWhenPrintingTheDboThenItListsItsFields', () {
    // given
    const dbo = SaveHeroDBOMock.mock;

    // when
    final text = dbo.toString();

    // then
    expect(text, startsWith('SaveHeroDBO('));
    expect(text, contains('weaponTier: 2'));
  });
}
