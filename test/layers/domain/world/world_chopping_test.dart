import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/chop_result.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/world/world.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../mocks/domain/entities/player/intent_entity_mock.dart';

void main() {
  test('testWhenChoppingWithoutAxeThenReturnsNoAxeAndStaysPut', () {
    // given
    final world = WorldMock.make(trees: [TreeEntityMock.mock]);

    // when
    final result = world.orderChop('tree-1');

    // then
    expect(result, ChopResult.noAxe);
    expect(world.player.isMoving, isFalse);
  });

  test('testWhenChoppingUnknownTreeThenReturnsUnknownTree', () {
    // given
    final world = WorldMock.withAxeAndTree();

    // when
    final result = world.orderChop('nope');

    // then
    expect(result, ChopResult.unknownTree);
  });

  test('testWhenChoppingThenWalksToTheNearSideAndStartsWorking', () {
    // given
    final world = WorldMock.withAxeAndTree();

    // when
    final result = world.orderChop('tree-1');
    world.advanceFor(1500);

    // then
    expect(result, ChopResult.ok);
    expect((world.player.activity as WorkingActivityEntity).intent, IntentEntityMock.chop);
    expect(world.player.position, const PositionEntity(x: 180, y: 101));
  });

  test('testWhenNearSideIsBlockedThenChopsFromTheOtherSide', () {
    // given
    final world = WorldMock.withAxeAndTreeWithNeighbour();
    world.orderChop('tree-1');

    // when
    world.advanceFor(4000);

    // then
    expect(world.player.activity, isA<WorkingActivityEntity>());
    expect(world.player.position.x, greaterThan(200));
  });

  test('testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded', () {
    // given
    final world = WorldMock.withAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500);

    // when
    final events = world.advanceFor(Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell + 100);

    // then
    expect(events.whereType<TreeHitEventEntity>().length, 5);
    expect(events, contains(GameEventEntityMock.treeFelled));
    expect(world.player.inventory.amount(Resource.wood), 6);
    expect(world.trees, isEmpty);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenAnotherTreeStandsInTheWayThenReportsPlayerBlocked', () {
    // given
    final world = WorldMock.withAxeAndTreeInTheWay();
    world.orderChop('tree-1');

    // when
    final events = world.advanceFor(3000);

    // then
    expect(events, contains(GameEventEntityMock.playerBlocked));
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenTreeIsFelledThenPathIsFree', () {
    // given
    final world = WorldMock.withAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500 + Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell + 100);

    // when
    world.movePlayerTo(const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000);

    // then
    expect(world.player.position, const PositionEntity(x: 300, y: 100));
  });

  List<TreeHitEventEntity> chopToTheEnd(World world) {
    world.orderChop('tree-1');
    return world.advanceFor(15000, stepMs: 50).whereType<TreeHitEventEntity>().toList();
  }

  test('testWhenTheAxeIsAtLevelOneThenAPineTakesThreeHitsAndAnOakSeven', () {
    // given
    final pine = WorldMock.restored(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.pineOfThree]);
    final oak = WorldMock.restored(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.oakOfEight]);

    // when
    final pineHits = chopToTheEnd(pine);
    final oakHits = chopToTheEnd(oak);

    // then
    expect(pineHits.map((hit) => hit.hitsRemaining), [2, 1, 0]);
    expect(oakHits.map((hit) => hit.hitsRemaining), [6, 5, 4, 3, 2, 1, 0]);
  });

  test('testWhenTheAxeIsUpgradedThenAPineTakesTwoHitsAndAnOakFive', () {
    // given
    final pine = WorldMock.restored(player: PlayerEntityMock.withIronAxe, trees: [TreeEntityMock.pineOfThree]);
    final oak = WorldMock.restored(player: PlayerEntityMock.withIronAxe, trees: [TreeEntityMock.oakOfEight]);

    // when
    final pineHits = chopToTheEnd(pine);
    final oakHits = chopToTheEnd(oak);

    // then
    expect(pineHits.map((hit) => hit.hitsRemaining), [1, 0]);
    expect(oakHits.map((hit) => hit.hitsRemaining), [4, 3, 2, 1, 0]);
    expect([...pine.trees, ...oak.trees], isEmpty);
  });

  test('testWhenAHalfChoppedTreeIsHitWithTheUpgradedAxeThenItFallsOnTheNextHit', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withIronAxe, trees: [TreeEntityMock.withThreeHitsTaken]);

    // when
    final hits = chopToTheEnd(world);

    // then
    expect(hits.map((hit) => hit.hitsRemaining), [0]);
    expect(world.trees, isEmpty);
  });

  test('testWhenTheAxeIsUpgradedOrAQuarryIsNearThenTheHitsStillComeEverySevenHundredFiftyMilliseconds', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.withIronAxe,
      trees: [TreeEntityMock.oakOfEight],
      buildings: [BuildingEntityMock.completed(Blueprints.quarry, position: const PositionEntity(x: 200, y: 200))],
    );
    world.orderChop('tree-1');

    // when
    final times = <double>[];
    var clock = 0.0;
    while (clock < 10000) {
      clock += 25;
      if (world.advance(25).any((event) => event is TreeHitEventEntity)) times.add(clock);
    }

    // then
    expect({for (var i = 1; i < times.length; i++) times[i] - times[i - 1]}, {750.0});
  });
}
