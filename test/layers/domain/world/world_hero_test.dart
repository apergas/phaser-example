import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/domain/rules/gear.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';

import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenCreatingAWorldWithoutHeroThenTheHeroIsTheBasicOne', () {
    // given
    final world = WorldMock.make();

    // when
    final hero = world.hero;

    // then
    expect(hero, HeroEntityMock.mock);
  });

  test('testWhenCreatingAWorldWithAHeroThenItKeepsThatHero', () {
    // given
    final world = WorldMock.withHero(HeroEntityMock.veteran);

    // when
    final hero = world.hero;

    // then
    expect(hero, HeroEntityMock.veteran);
  });

  test('testWhenUpdatingTheHeroThenTheWorldKeepsTheNewHero', () {
    // given
    final world = WorldMock.make();

    // when
    world.updateHero((hero) => hero.withGear(Gear.byId(GearId.shortSword)).withGear(Gear.byId(GearId.leatherArmor)));

    // then
    expect(world.hero, HeroEntityMock.withShortSwordAndLeather);
  });
}
