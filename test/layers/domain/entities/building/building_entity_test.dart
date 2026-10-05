import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';

void main() {
  test('testWhenBuildingHasNoHitsThenProgressIsZeroAndItIsNotComplete', () {
    // given
    const building = BuildingEntityMock.mock;

    // when
    final progress = building.progress;
    final isComplete = building.isComplete;

    // then
    expect(progress, 0.0);
    expect(isComplete, isFalse);
  });

  test('testWhenHalfOfTheHitsAreDoneThenProgressIsHalfAndItIsNotComplete', () {
    // given
    const building = BuildingEntityMock.halfBuilt;

    // when
    final progress = building.progress;
    final isComplete = building.isComplete;

    // then
    expect(progress, 0.5);
    expect(isComplete, isFalse);
  });

  test('testWhenAllHitsAreDoneThenProgressIsOneAndItIsComplete', () {
    // given
    const building = BuildingEntityMock.complete;

    // when
    final progress = building.progress;
    final isComplete = building.isComplete;

    // then
    expect(progress, 1.0);
    expect(isComplete, isTrue);
  });

  test('testWhenAskingForTheFootprintThenItUsesPositionAndBlueprintRadius', () {
    // given
    const building = BuildingEntityMock.mock;

    // when
    final footprint = building.footprint;

    // then
    expect(footprint, ObstacleEntityMock.houseFootprint);
  });

  test('testWhenComparingBuildingsThenEveryFieldMatters', () {
    // given
    const building = BuildingEntityMock.mock;

    // when
    final copy = building.copyWith();
    final otherId = building == building.copyWith(id: 'building-2');
    final otherPosition = building == building.copyWith(position: const PositionEntity(x: 1, y: 1));
    final otherHits = building == building.copyWith(hitsDone: 1);

    // then
    expect(copy, building);
    expect(copy.hashCode, building.hashCode);
    expect(otherId, isFalse);
    expect(otherPosition, isFalse);
    expect(otherHits, isFalse);
  });
}
