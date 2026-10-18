import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/enemy_kind.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/domain/world/extensions/enemy_kind_rules.dart';

void main() {
  test('testWhenAskingEachEnemyKindForItsSkillsThenTheyMatchTheTable', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final skills = {for (final kind in kinds) kind: kind.skills};

    // then
    expect(skills, {
      EnemyKind.bandit: {SkillId.dodge},
      EnemyKind.barbarian: {SkillId.doubleStrike},
      EnemyKind.barbarianChief: {SkillId.doubleStrike, SkillId.secondWind},
      EnemyKind.wolf: {SkillId.doubleStrike},
      EnemyKind.bear: {SkillId.doubleStrike},
      EnemyKind.banditVeteran: {SkillId.dodge},
    });
  });

  test('testWhenAskingEveryEnemyKindThenEachOneHasAtLeastOneSkill', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final withoutSkills = kinds.where((kind) => kind.skills.isEmpty);

    // then
    expect(withoutSkills, isEmpty);
  });
}
