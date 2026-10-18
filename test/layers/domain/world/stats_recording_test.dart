import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../mocks/domain/entities/tree/stump_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenATreeIsFelledThenTheTotalAndItsKindAreCountedInTheSameTick', () {
    // given
    final world = WorldMock.withAxeAndTree();
    world.orderChop('tree-1');

    // when
    final before = <Object>[];
    var felled = false;
    while (!felled) {
      before.add(world.stats);
      felled = world.advance(50).any((event) => event is TreeFelledEventEntity);
    }

    // then
    expect(before.toSet(), {StatsEntityMock.empty});
    expect(world.stats, StatsEntityMock.afterOneOak);
  });

  test('testWhenABuildingIsCompletedThenItIsCountedInTheSameTick', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.mock,
      buildings: [BuildingEntityMock.site(Blueprints.house, position: TreeEntityMock.mock.position)],
    );
    world.orderResumeConstruction('building-1');

    // when
    var completedAt = -1;
    for (var tick = 0; tick < 1000 && completedAt < 0; tick++) {
      if (world.advance(50).any((event) => event is BuildingCompletedEventEntity)) completedAt = tick;
    }

    // then
    expect(completedAt, greaterThanOrEqualTo(0));
    expect(world.stats, StatsEntityMock.afterOneHouse);
  });

  test('testWhenATreeRegrowsThenItIsCountedInTheSameTick', () {
    // given
    final world = WorldMock.restored(stumps: [StumpEntityMock.almostReady]);

    // when
    final events = world.advance(50);

    // then
    expect(events.whereType<TreeRegrownEventEntity>(), hasLength(1));
    expect(world.stats, StatsEntityMock.afterOneRegrowth);
  });

  test('testWhenOnlyARockIsHitThenNothingIsCounted', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    world.advanceFor(20000, stepMs: 50);

    // then
    expect(world.rocks, isEmpty);
    expect(world.stats, StatsEntityMock.empty);
  });
}
