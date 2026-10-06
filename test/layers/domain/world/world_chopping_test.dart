import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
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
    final events = world.advanceFor(Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

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
    world.advanceFor(1500 + Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

    // when
    world.movePlayerTo(const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000);

    // then
    expect(world.player.position, const PositionEntity(x: 300, y: 100));
  });
}
