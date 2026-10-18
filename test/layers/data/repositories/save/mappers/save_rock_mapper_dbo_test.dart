import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_rock_mapper_dbo.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../../../mocks/data/datasources/save/save_rock_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/rock/rock_entity_mock.dart';

void main() {
  late SaveRockMapperDBO sut;

  setUp(() {
    sut = SaveRockMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingARockToDboThenItKeepsTheHitsTaken', () {
    // given
    const rock = RockEntityMock.onceHit;

    // when
    final dbo = sut.toDBO(rock);

    // then
    expect(dbo, SaveRockDBOMock.onceHit);
  });

  test('testWhenMappingADboToARockThenTheSizeAndYieldComeFromTheRules', () {
    // given
    const dbo = SaveRockDBOMock.onceHit;

    // when
    final rock = sut.toEntity(dbo);

    // then
    expect(rock, RockEntityMock.onceHit);
    expect(rock.radius, Rules.rockRadius);
    expect(rock.stoneYield, Rules.rockStoneYield);
    expect(rock.hitsToBreak, Rules.rockHitsToBreak);
  });

  test('testWhenTheRockHasNoHitsThenItIsIntact', () {
    // given
    const dbo = SaveRockDBOMock.intact;

    // when
    final rock = sut.toEntity(dbo);

    // then
    expect(rock.hitsTaken, 0);
  });

  test('testWhenTheHitsAreOneBelowTheTotalThenTheRockLoads', () {
    // given
    const dbo = SaveRockDBOMock.almostBroken;

    // when
    final rock = sut.toEntity(dbo);

    // then
    expect(rock.hitsTaken, Rules.rockHitsToBreak - 1);
  });

  test('testWhenTheHitsReachTheTotalThenItThrows', () {
    // given
    const dbo = SaveRockDBOMock.broken;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('rock rock-1: 8 hits taken of 8'));
  });

  test('testWhenTheHitsAreNegativeThenItThrows', () {
    // given
    const dbo = SaveRockDBOMock.withNegativeHits;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('rock rock-1: -1 hits taken of 8'));
  });

  test('testWhenTheRockHasNoIdThenItThrows', () {
    // given
    const dbo = SaveRockDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('rock without id'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveRockDBOMock.withoutX, SaveRockDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('rock rock-1 without x'));
    expect(attempts[1], throwsInvalidSave('rock rock-1 without y'));
  });
}
