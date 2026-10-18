import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_hero_mapper_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_hero_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_hero_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SaveHeroMapperDBO sut;

  setUp(() {
    sut = SaveHeroMapperDBO();
  });

  test('testWhenMappingAHeroToDboThenTiersSkillsAndLevelsKeepTheirNames', () {
    // given
    const hero = SaveScenarioMock.hero;

    // when
    final dbo = sut.toDBO(hero);

    // then
    expect(dbo, SaveHeroDBOMock.mock);
  });

  test('testWhenMappingADboToAHeroThenEveryFieldComesBack', () {
    // given
    const dbo = SaveHeroDBOMock.mock;

    // when
    final hero = sut.toEntity(dbo);

    // then
    expect(hero, SaveScenarioMock.hero);
  });

  test('testWhenThereIsNoDboOrItHasNoFieldsThenTheHeroIsTheStartingOne', () {
    // given
    const SaveHeroDBO? missing = null;
    const empty = SaveHeroDBOMock.empty;

    // when
    final fromNothing = sut.toEntity(missing);
    final fromEmpty = sut.toEntity(empty);

    // then
    expect(fromNothing, HeroEntityMock.mock);
    expect(fromEmpty, HeroEntityMock.mock);
  });

  test('testWhenTheTiersAndSkillLevelsAreAtTheirMaximumThenTheHeroLoads', () {
    // given
    const gear = SaveHeroDBOMock.withMaxTiers;
    const skill = SaveHeroDBOMock.withMaxSkillLevel;

    // when
    final geared = sut.toEntity(gear);
    final skilled = sut.toEntity(skill);

    // then
    expect((geared.weaponTier, geared.armorTier), (3, 3));
    expect(skilled.skillLevels, {SkillId.secondWind: 3});
  });

  test('testWhenAWeaponTierIsOutOfTheCatalogueThenItThrows', () {
    // given
    const dbos = [SaveHeroDBOMock.weaponTierTooHigh, SaveHeroDBOMock.weaponTierNegative];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('hero: weapon tier 4'));
    expect(attempts[1], throwsInvalidSave('hero: weapon tier -1'));
  });

  test('testWhenAnArmorTierIsOutOfTheCatalogueThenItThrows', () {
    // given
    const dbos = [SaveHeroDBOMock.armorTierTooHigh, SaveHeroDBOMock.armorTierNegative];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('hero: armor tier 4'));
    expect(attempts[1], throwsInvalidSave('hero: armor tier -1'));
  });

  test('testWhenASkillIsUnknownThenItThrows', () {
    // given
    const dbo = SaveHeroDBOMock.unknownSkill;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('hero: unknown skill "fireball"'));
  });

  test('testWhenASkillLevelIsOutOfRangeThenItThrows', () {
    // given
    const dbos = [SaveHeroDBOMock.skillLevelZero, SaveHeroDBOMock.skillLevelTooHigh];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('hero: dodge level 0 of 3'));
    expect(attempts[1], throwsInvalidSave('hero: dodge level 4 of 3'));
  });

  test('testWhenAClearedLevelIsUnknownThenItThrows', () {
    // given
    const dbo = SaveHeroDBOMock.unknownLevel;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('hero: unknown level "dragon"'));
  });

  test('testWhenTheFightsAreNegativeThenItThrows', () {
    // given
    const dbo = SaveHeroDBOMock.negativeFights;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('hero: -1 fights'));
  });
}
