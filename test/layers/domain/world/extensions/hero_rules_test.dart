import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/domain/rules/gear.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';

import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';

void main() {
  test('testWhenTheHeroHasBasicGearThenStatsAreTheBaseStats', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroBase);
    expect(hero.power, 31);
  });

  test('testWhenTheHeroHasShortSwordAndLeatherThenStatsAddBothPieces', () {
    // given
    const hero = HeroEntityMock.withShortSwordAndLeather;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroWithShortSwordAndLeather);
  });

  test('testWhenTheHeroKnowsTwoSkillsThenPowerGrowsTwentyPercent', () {
    // given
    const hero = HeroEntityMock.withTwoSkills;

    // when
    final power = hero.power;

    // then
    expect(power, 64);
  });

  test('testWhenTheHeroIsFullyGearedThenThereIsNoNextGear', () {
    // given
    const hero = HeroEntityMock.fullyGeared;

    // when
    final next = (hero.nextGear(GearSlot.weapon), hero.nextGear(GearSlot.armor));

    // then
    expect(next, (null, null));
    expect(hero.stats, CombatStatsEntityMock.heroFullyGeared);
    expect(hero.power, 144);
  });

  test('testWhenEquippingGearThenOnlyItsSlotTierChanges', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final equipped = hero.withGear(Gear.byId(GearId.ironSword));

    // then
    expect((equipped.tierOf(GearSlot.weapon), equipped.tierOf(GearSlot.armor)), (2, 0));
    expect(equipped.equipped(GearSlot.weapon).id, GearId.ironSword);
  });
}
