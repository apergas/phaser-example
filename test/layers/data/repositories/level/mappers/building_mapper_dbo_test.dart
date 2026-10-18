import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/error-handling/exceptions/app_exceptions.dart';
import 'package:farming/layers/data/repositories/level/mappers/building_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

import '../../../../../mocks/data/datasources/level/building_dbo_mock.dart';

void main() {
  late BuildingMapperDBO sut;

  setUp(() {
    sut = BuildingMapperDBO();
  });

  test('testWhenMappingTheCampThenItArrivesFinished', () {
    // given
    const dbo = BuildingDBOMock.camp;

    // when
    final building = sut.toEntity(dbo, index: 0);

    // then
    expect(
      (building.id, building.blueprint, building.position),
      ('camp', Blueprints.camp, const PositionEntity(x: 700, y: 592)),
    );
    expect(building.isComplete, isTrue);
    expect(building.hitsDone, Blueprints.camp.hitsToBuild);
  });

  test('testWhenMappingAStorehouseThenItArrivesFinishedToo', () {
    // given
    const dbo = BuildingDBOMock.storehouse;

    // when
    final building = sut.toEntity(dbo, index: 0);

    // then
    expect((building.blueprint, building.isComplete), (Blueprints.storehouse, true));
  });

  test('testWhenTheBuildingHasNoIdThenItIsNamedAfterItsPositionInTheList', () {
    // given
    const dbo = BuildingDBOMock.withoutId;

    // when
    final building = sut.toEntity(dbo, index: 1);

    // then
    expect(building.id, 'level-building-2');
  });

  test('testWhenTheBuildingHasNoPositionThenItIsAtTheOrigin', () {
    // given
    const dbo = BuildingDBOMock.withoutPosition;

    // when
    final building = sut.toEntity(dbo, index: 0);

    // then
    expect(building.position, const PositionEntity(x: 0, y: 0));
  });

  test('testWhenTheBlueprintIsUnknownOrMissingThenItThrowsInvalidLevelException', () {
    // given
    const unknown = BuildingDBOMock.unknownBlueprint;
    const missing = BuildingDBOMock.withoutBlueprint;

    // when
    void mapUnknown() => sut.toEntity(unknown, index: 0);
    void mapMissing() => sut.toEntity(missing, index: 0);

    // then
    expect(
      mapUnknown,
      throwsA(
        isA<InvalidLevelException>().having(
          (exception) => exception.data,
          'data',
          'unknown blueprint castle-1: "castle"',
        ),
      ),
    );
    expect(mapMissing, throwsA(isA<InvalidLevelException>()));
  });
}
