import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';

import '../../../../mocks/domain/entities/hero/skill_entity_mock.dart';

void main() {
  test('testWhenComparingSkillsThenIdAndCostBothCount', () {
    // given
    const skill = SkillEntityMock.doubleStrike;

    // when
    final sameSkill = skill == skill.copyWith();
    final otherId = skill == skill.copyWith(id: SkillId.dodge);
    final otherCost = skill == skill.copyWith(costs: SkillEntityMock.dodge.costs);

    // then
    expect(sameSkill, isTrue);
    expect(skill.hashCode, skill.copyWith().hashCode);
    expect(otherId, isFalse);
    expect(otherCost, isFalse);
  });
  test('testWhenAskingForTheCostOfALevelThenItIsThatEntryAndTheMaxLevelIsTheNumberOfEntries', () {
    // given
    const skill = SkillEntityMock.doubleStrike;

    // when
    final costs = [skill.costOf(1), skill.costOf(2), skill.costOf(3)];

    // then
    expect(costs, skill.costs);
    expect(skill.maxLevel, 3);
    expect(SkillEntityMock.singleLevelDoubleStrike.maxLevel, 1);
  });
}
