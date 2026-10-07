import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';

import '../../../../mocks/domain/entities/hero/skill_entity_mock.dart';

void main() {
  test('testWhenComparingSkillsThenIdAndCostBothCount', () {
    // given
    const skill = SkillEntityMock.doubleStrike;

    // when
    final sameSkill = skill == skill.copyWith();
    final otherId = skill == skill.copyWith(id: SkillId.dodge);
    final otherCost = skill == skill.copyWith(cost: SkillEntityMock.dodge.cost);

    // then
    expect(sameSkill, isTrue);
    expect(skill.hashCode, skill.copyWith().hashCode);
    expect(otherId, isFalse);
    expect(otherCost, isFalse);
  });
}
