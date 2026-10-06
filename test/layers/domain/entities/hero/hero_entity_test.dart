import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';

import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';

void main() {
  test('testWhenCreatingAHeroThenItStartsWithBasicGearNoSkillsAndNoFights', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final tiers = (hero.weaponTier, hero.armorTier, hero.fightsFought);

    // then
    expect(tiers, (0, 0, 0));
    expect(hero.skills, isEmpty);
    expect(hero.clearedLevels, isEmpty);
  });

  test('testWhenCopyingWithTiersThenSkillsAndProgressAreKept', () {
    // given
    const hero = HeroEntityMock.withTwoSkills;

    // when
    final copy = hero.copyWith(weaponTier: 3, armorTier: 3, skills: {...hero.skills, SkillId.secondWind});

    // then
    expect(copy, HeroEntityMock.fullyGeared);
    expect(copy.hashCode, HeroEntityMock.fullyGeared.hashCode);
  });

  test('testWhenSkillsDifferThenHeroesAreNotEqual', () {
    // given
    const hero = HeroEntityMock.withShortSwordAndLeather;

    // when
    final equal = hero == HeroEntityMock.withTwoSkills;

    // then
    expect(equal, isFalse);
  });
}
