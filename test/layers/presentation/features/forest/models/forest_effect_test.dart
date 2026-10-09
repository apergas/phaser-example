import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';

void main() {
  test('testWhenComparingEffectsWithTheSameValuesThenTheyAreEqual', () {
    // given
    final first = ForestEffectMock.treeFelled;
    final second = ForestEffectMock.treeFelledCopy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenEffectsOfDifferentKindsShareTheTreeThenTheyAreNotEqual', () {
    // given
    final hit = ForestEffectMock.treeHit;
    final felled = ForestEffectMock.treeFelled;

    // when
    final isEqual = hit == felled;

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenComparingGearPurchasesThenOnlyTheSamePieceIsEqual', () {
    // given
    const first = ForestEffectMock.shortSwordPurchased;

    // when
    final sameGear = first == ForestEffectMock.shortSwordPurchasedCopy;
    final otherGear = first == ForestEffectMock.leatherArmorPurchased;

    // then
    expect(sameGear, isTrue);
    expect(first.hashCode, ForestEffectMock.shortSwordPurchasedCopy.hashCode);
    expect(otherGear, isFalse);
  });

  test('testWhenComparingLearnedSkillsThenOnlyTheSameSkillIsEqual', () {
    // given
    const first = ForestEffectMock.doubleStrikeLearned;

    // when
    final sameSkill = first == ForestEffectMock.doubleStrikeLearnedCopy;
    final otherSkill = first == ForestEffectMock.dodgeLearned;

    // then
    expect(sameSkill, isTrue);
    expect(first.hashCode, ForestEffectMock.doubleStrikeLearnedCopy.hashCode);
    expect(otherSkill, isFalse);
  });
}
