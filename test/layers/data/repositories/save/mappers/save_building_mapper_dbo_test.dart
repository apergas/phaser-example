import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_building_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

import '../../../../../mocks/data/datasources/save/save_building_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/building/building_entity_mock.dart';

void main() {
  late SaveBuildingMapperDBO sut;

  setUp(() {
    sut = SaveBuildingMapperDBO(positionMapperDBO: SavePositionMapperDBO());
  });

  test('testWhenMappingBuildingsToDboThenTheyKeepTheBlueprintByNameAndTheProgress', () {
    // given
    final buildings = [BuildingEntityMock.halfBuilt, BuildingEntityMock.finishedHouse];

    // when
    final dbos = buildings.map(sut.toDBO).toList();

    // then
    expect(dbos, [SaveBuildingDBOMock.halfBuilt, SaveBuildingDBOMock.house]);
  });

  test('testWhenMappingDbosToBuildingsThenTheBlueprintComesFromTheCatalogue', () {
    // given
    const dbos = [SaveBuildingDBOMock.halfBuilt, SaveBuildingDBOMock.house, SaveBuildingDBOMock.forgeSite];

    // when
    final buildings = dbos.map(sut.toEntity).toList();

    // then
    expect(buildings[0], BuildingEntityMock.halfBuilt);
    expect(buildings[1], BuildingEntityMock.finishedHouse);
    expect(buildings[2].blueprint, Blueprints.forge);
    expect(buildings[2].position, const PositionEntity(x: 900, y: 300));
    expect(buildings[2].hitsDone, 4);
  });

  test('testWhenTheBuildingHasNoHitsThenItIsASite', () {
    // given
    const dbo = SaveBuildingDBOMock.site;

    // when
    final building = sut.toEntity(dbo);

    // then
    expect(building, BuildingEntityMock.mock);
  });

  test('testWhenTheHitsEqualTheBlueprintTotalThenTheBuildingIsComplete', () {
    // given
    const dbo = SaveBuildingDBOMock.complete;

    // when
    final building = sut.toEntity(dbo);

    // then
    expect(building, BuildingEntityMock.complete);
  });

  test('testWhenTheHitsAreAboveTheTotalThenItThrows', () {
    // given
    const dbo = SaveBuildingDBOMock.withTooManyHits;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('building building-1: 9 hits of 8'));
  });

  test('testWhenTheHitsAreNegativeThenItThrows', () {
    // given
    const dbo = SaveBuildingDBOMock.withNegativeHits;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('building building-1: -1 hits of 8'));
  });

  test('testWhenTheBuildingHasNoIdThenItThrows', () {
    // given
    const dbo = SaveBuildingDBOMock.withoutId;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('building without id'));
  });

  test('testWhenTheBlueprintIsUnknownThenItThrows', () {
    // given
    const dbo = SaveBuildingDBOMock.unknownBlueprint;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('building building-1: unknown blueprint "castle"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SaveBuildingDBOMock.withoutX, SaveBuildingDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('building building-1 without x'));
    expect(attempts[1], throwsInvalidSave('building building-1 without y'));
  });
}
