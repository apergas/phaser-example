import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/core/config/constants/enum/skill_option_state.dart';

import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenSkillStateAndMissingAllCount', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAvailable;

    // when
    final sameOption = option == SkillOptionEntityMock.doubleStrikeAvailable;
    final otherMissing = option == SkillOptionEntityMock.doubleStrikeTenGoldShort;
    final otherState = option == option.copyWith(state: SkillOptionState.known);

    // then
    expect(sameOption, isTrue);
    expect(option.hashCode, SkillOptionEntityMock.doubleStrikeAvailable.hashCode);
    expect(otherMissing, isFalse);
    expect(otherState, isFalse);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeLearnedAndNoOtherStateCan', () {
    // given
    final available = SkillOptionEntityMock.doubleStrikeAvailable;
    final others = [
      SkillOptionEntityMock.known(SkillId.doubleStrike),
      SkillOptionEntityMock.doubleStrikeTenGoldShort,
      SkillOptionEntityMock.make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
    ];

    // when
    final learnable = others.where((option) => option.canLearn).toList();

    // then
    expect(available.canLearn, isTrue);
    expect(learnable, isEmpty);
  });
}
