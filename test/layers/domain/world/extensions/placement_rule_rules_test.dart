import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/world/extensions/placement_rule_rules.dart';

import '../../../../mocks/domain/entities/building/placement_rule_entity_mock.dart';
import '../../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../../mocks/domain/world/world_state_mock.dart';

void main() {
  const rock = RockEntityMock.intact;

  PositionEntity below(double distance) => PositionEntity(x: rock.position.x, y: rock.position.y + distance);

  test('testWhenTheRuleIsAnywhereThenThereIsNeverARejection', () {
    // given
    final state = WorldStateMock.make(width: 1000, height: 1000);

    // when
    final rejection = PlacementRuleEntityMock.anywhere.rejection(state, below(500));

    // then
    expect(rejection, isNull);
  });

  test('testWhenTheSiteIsCloserThanTheRangeToARockThenTheNearRockRulePasses', () {
    // given
    final state = WorldStateMock.make(width: 1000, height: 1000, rocks: [rock]);

    // when
    final rejections = [
      61.0,
      62.0,
      119.9,
    ].map((distance) => PlacementRuleEntityMock.nearRock.rejection(state, below(distance)));

    // then
    expect(rejections, [null, null, null]);
  });

  test('testWhenTheSiteIsAtTheRangeOrThereAreNoRocksThenItNeedsANearbyRock', () {
    // given
    final withRock = WorldStateMock.make(width: 1000, height: 1000, rocks: [rock]);
    final withoutRocks = WorldStateMock.make(width: 1000, height: 1000);

    // when
    final atTheRange = PlacementRuleEntityMock.nearRock.rejection(withRock, below(120));
    final noRocks = PlacementRuleEntityMock.nearRock.rejection(withoutRocks, below(61));

    // then
    expect((atTheRange, noRocks), (ConstructionRejection.needsNearbyRock, ConstructionRejection.needsNearbyRock));
  });

  test('testWhenTheRockIsBrokenAndRemovedThenItNoLongerCounts', () {
    // given
    final state = WorldStateMock.make(width: 1000, height: 1000, rocks: [rock]);
    state.rocks.remove(rock.id);

    // when
    final rejection = PlacementRuleEntityMock.nearRock.rejection(state, below(61));

    // then
    expect(rejection, ConstructionRejection.needsNearbyRock);
  });
}
