import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/extensions/position_geometry.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../mocks/domain/entities/tree/stump_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/game/level_scenario_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  const tickMs = 50.0;

  test('testWhenTheNearestPineIsFelledInTheForestThenItSproutsAMinuteLaterAndComesBackThreeMinutesLater', () {
    // given
    final world = LevelScenarioMock.forest();
    final times = <String, double>{};
    var clock = 0.0;
    void tick() {
      clock += tickMs;
      for (final event in world.advance(tickMs)) {
        final name = switch (event) {
          TreeFelledEventEntity() => 'felled',
          TreeSproutedEventEntity() => 'sprouted',
          TreeRegrownEventEntity() => 'regrown',
          _ => null,
        };
        if (name != null) times[name] = clock;
      }
    }

    world.movePlayerTo(LevelScenarioMock.oldAxeSpot);
    while (world.player.activity is! IdleActivityEntity) {
      tick();
    }
    final pines = world.trees.where((tree) => tree.kind == TreeKind.pine).toList()
      ..sort(
        (a, b) => a.position.distanceTo(world.player.position).compareTo(b.position.distanceTo(world.player.position)),
      );
    final pine = pines.first;

    // when
    world.orderChop(pine.id);
    while (!times.containsKey('regrown') && clock < 200000) {
      tick();
    }

    // then
    expect(pine.id, 'tree-37');
    expect(times, {'felled': 5500, 'sprouted': 65500, 'regrown': 185500});
    expect(world.trees.last, pine);
  });

  test('testWhenATreeIsFelledThenItLeavesAStumpWithItsIdKindAndPlaceThatEndsTheTickAtZero', () {
    // given
    final world = WorldMock.withAxeAndTree();
    world.orderChop('tree-1');

    // when
    var felled = false;
    while (!felled) {
      felled = world.advance(tickMs).any((event) => event is TreeFelledEventEntity);
    }

    // then
    expect(world.stumps, [StumpEntityMock.freshOak]);
  });

  test('testWhenTheStumpCrossesOneMinuteThenItSproutsOnlyOnce', () {
    // given
    final world = WorldMock.restored(stumps: [StumpEntityMock.almostSapling]);

    // when
    final first = world.advance(1);
    final second = world.advance(tickMs);

    // then
    expect(first, [GameEventEntityMock.stumpSprouted]);
    expect(second, isEmpty);
  });

  test('testWhenOneAdvanceCrossesBothThresholdsThenItSproutsAndRegrowsInThatOrder', () {
    // given
    final world = WorldMock.restored(stumps: [StumpEntityMock.fresh]);

    // when
    final events = world.advance(180000);

    // then
    expect(events, [GameEventEntityMock.stumpSprouted, GameEventEntityMock.pineRegrown]);
    expect(world.stumps, isEmpty);
  });

  test('testWhenTheTreeComesBackThenItHasTheStumpIdKindPlaceAndFreshStatsAndIsTheLastTree', () {
    // given
    final world = WorldMock.restored(trees: [TreeEntityMock.neighbour], stumps: [StumpEntityMock.almostReady]);

    // when
    world.advance(tickMs);

    // then
    expect(world.trees, [TreeEntityMock.neighbour, TreeEntityMock.regrownPine]);
    expect(world.trees.last.hitsTaken, 0);
  });

  test('testWhenThePlayerStandsOnTheStumpThenTheTreeWaitsAtThreeMinutes', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.onTheStump, stumps: [StumpEntityMock.almostReady]);

    // when
    final events = world.advanceFor(1000, stepMs: tickMs);

    // then
    expect(events, isEmpty);
    expect(world.stumps, [StumpEntityMock.ready]);
  });

  test('testWhenThePlayerStandsWhereItChopsThenTheTreeComesBack', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.besideTheStump, stumps: [StumpEntityMock.almostReady]);

    // when
    final events = world.advance(tickMs);

    // then
    expect(events, [GameEventEntityMock.pineRegrown]);
  });

  test('testWhenARockIsCloserThanThirtyFourThenTheTreeWaitsAndFurtherItComesBack', () {
    // given
    final blocked = WorldMock.restored(rocks: [RockEntityMock.nextToStump], stumps: [StumpEntityMock.almostReady]);
    final free = WorldMock.restored(rocks: [RockEntityMock.nearStump], stumps: [StumpEntityMock.almostReady]);

    // when
    final whenBlocked = blocked.advance(tickMs);
    final whenFree = free.advance(tickMs);

    // then
    expect(whenBlocked, isEmpty);
    expect(whenFree, [GameEventEntityMock.pineRegrown]);
  });

  test('testWhenAHouseIsPlacedCloserThanFiftyTwoThenTheStumpIsGoneAndFurtherItStays', () {
    // given
    World stockedWithStump() => WorldMock.restored(
      stumps: [StumpEntityMock.fresh],
      stock: StockEntityMock.make(wood: 15),
    );
    final near = stockedWithStump();
    final far = stockedWithStump();

    // when
    near.orderConstruction(Blueprints.house, const PositionEntity(x: 200, y: 151));
    far.orderConstruction(Blueprints.house, const PositionEntity(x: 200, y: 153));

    // then
    expect(near.stumps, isEmpty);
    expect(near.buildings, hasLength(1));
    expect(far.stumps, [StumpEntityMock.fresh]);
    expect(far.buildings, hasLength(1));
  });

  test('testWhenThereIsAStumpThenItBlocksNeitherThePathNorABuilding', () {
    // given
    final world = WorldMock.restored(stumps: [StumpEntityMock.fresh]);

    // when
    final rejection = world.placementRejection(Blueprints.house, StumpEntityMock.site);

    // then
    expect(world.obstacles, isEmpty);
    expect(rejection, isNull);
  });

  test('testWhenTheStumpSproutsInTheSameTickAsAHitThenTheSproutComesFirst', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.aboutToHitTheTree,
      trees: [TreeEntityMock.mock],
      stumps: [StumpEntityMock.elsewhereAlmostSapling],
    );

    // when
    final events = world.advance(1);

    // then
    expect(events.first, GameEventEntityMock.otherStumpSprouted);
    expect(events[1], isA<TreeHitEventEntity>());
  });
}
