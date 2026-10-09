import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/rules/skills.dart';

import '../../../mocks/domain/entities/hero/skill_entity_mock.dart';

void main() {
  test('testWhenListingSkillsThenEverySkillIdAppearsOnce', () {
    // given
    final ids = Skills.all.map((skill) => skill.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(SkillId.values.length));
    expect(unique, SkillId.values.toSet());
  });

  test('testWhenAskingForEachSkillThenItCostsOnlyGoldFromCheapestToDearest', () {
    // given
    final ids = [SkillId.doubleStrike, SkillId.dodge, SkillId.secondWind];

    // when
    final skills = ids.map(Skills.byId).toList();
    final prices = Skills.all.map((skill) => skill.cost[Resource.gold]).toList();

    // then
    expect(skills, [SkillEntityMock.doubleStrike, SkillEntityMock.dodge, SkillEntityMock.secondWind]);
    expect(prices, [60, 90, 130]);
  });

  test('testWhenAskingWhereSkillsAreLearnedThenItIsTheMageTower', () {
    // given
    const expected = BlueprintId.mageTower;

    // when
    const building = Skills.building;

    // then
    expect(building, expected);
  });
}
