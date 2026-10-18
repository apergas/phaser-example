import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/skill_option_state.dart';
import 'package:farming/layers/domain/rules/skills.dart';

import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenSkillLevelStateAndMissingAllCount', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAvailable;

    // when
    final sameOption = option == SkillOptionEntityMock.doubleStrikeAvailable;
    final otherMissing = option == SkillOptionEntityMock.doubleStrikeTenGoldShort;
    final otherState = option == option.copyWith(state: SkillOptionState.unaffordable);
    final otherLevel = option == SkillOptionEntityMock.doubleStrikeAtLevelOneAvailable;

    // then
    expect(sameOption, isTrue);
    expect(option.hashCode, SkillOptionEntityMock.doubleStrikeAvailable.hashCode);
    expect(otherMissing, isFalse);
    expect(otherState, isFalse);
    expect(otherLevel, isFalse);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeLearnedAndNoOtherStateCan', () {
    // given
    final available = SkillOptionEntityMock.doubleStrikeAvailable;
    final others = [
      SkillOptionEntityMock.maxed(SkillId.doubleStrike),
      SkillOptionEntityMock.doubleStrikeTenGoldShort,
      SkillOptionEntityMock.make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
    ];

    // when
    final learnable = others.where((option) => option.canLearn).toList();

    // then
    expect(available.canLearn, isTrue);
    expect(learnable, isEmpty);
  });

  test('testWhenTheSkillIsNotLearnedThenTheNextLevelIsOneAtTheFirstCost', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAvailable;

    // when
    final next = (option.nextLevel, option.nextCost);

    // then
    expect(next, (1, Skills.doubleStrike.costs[0]));
  });

  test('testWhenTheSkillIsAtLevelTwoThenTheNextLevelIsThreeAtTheThirdCost', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAtLevelTwoAvailable;

    // when
    final next = (option.nextLevel, option.nextCost);

    // then
    expect(next, (3, Skills.doubleStrike.costs[2]));
  });

  test('testWhenTheSkillIsAtTheMaxLevelThenThereIsNoNextLevelNorCost', () {
    // given
    final option = SkillOptionEntityMock.maxed(SkillId.doubleStrike);

    // when
    final next = (option.nextLevel, option.nextCost);

    // then
    expect(next, (null, null));
  });

  test('testWhenTheLevelIsNegativeThenItAsserts', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAvailable;

    // when
    void call() => option.copyWith(level: -1);

    // then
    expect(call, throwsA(isA<AssertionError>()));
  });
}
