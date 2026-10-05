import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/world/extensions/building_rules.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';

void main() {
  test('testWhenHammeredThenProgressGrowsUntilComplete', () {
    // given
    var building = BuildingEntityMock.mock;

    // when
    building = building.hammer();
    final afterOneHit = building.progress;
    for (var i = 0; i < 7; i++) {
      building = building.hammer();
    }

    // then
    expect(afterOneHit, 0.125);
    expect(building.isComplete, isTrue);
  });

  test('testWhenCompleteThenHammerDoesNothing', () {
    // given
    final complete = BuildingEntityMock.mock.copyWith(hitsDone: 8);

    // when
    final hammered = complete.hammer();

    // then
    expect(hammered, same(complete));
  });

  test('testWhenPlacedThenFootprintUsesTheBlueprintRadius', () {
    // given
    const building = BuildingEntityMock.mock;

    // when
    final footprint = building.footprint;

    // then
    expect(footprint, ObstacleEntityMock.houseFootprint);
    expect(building.progress, 0.0);
    expect(building.isComplete, isFalse);
  });
}
