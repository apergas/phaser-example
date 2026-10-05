import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

World _worldWithAxeAndTree() {
  final player = PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe));
  return WorldMock.make(player: player, trees: [TreeEntityMock.mock]);
}

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
    final world = _worldWithAxeAndTree();

    // when
    final result = world.orderChop('nope');

    // then
    expect(result, ChopResult.unknownTree);
  });

  test('testWhenChoppingThenWalksToTheNearSideAndStartsWorking', () {
    // given
    final world = _worldWithAxeAndTree();

    // when
    final result = world.orderChop('tree-1');
    world.advanceFor(1500);

    // then
    expect(result, ChopResult.ok);
    expect((world.player.activity as WorkingActivityEntity).intent, const ChopIntentEntity(treeId: 'tree-1'));
    expect(world.player.position, const PositionEntity(x: 180, y: 101));
  });

  test('testWhenNearSideIsBlockedThenChopsFromTheOtherSide', () {
    // given
    final player = PlayerEntityMock.mock.copyWith(
      position: const PositionEntity(x: 100, y: 300),
      inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe),
    );
    final world = WorldMock.make(
      player: player,
      trees: [
        TreeEntityMock.mock,
        TreeEntityMock.mock.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100)),
      ],
    );
    world.orderChop('tree-1');

    // when
    world.advanceFor(4000);

    // then
    expect(world.player.activity, isA<WorkingActivityEntity>());
    expect(world.player.position.x, greaterThan(200));
  });

  test('testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded', () {
    // given
    final world = _worldWithAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500);

    // when
    final events = world.advanceFor(Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

    // then
    expect(events.whereType<TreeHitEventEntity>().length, 5);
    expect(events, contains(const TreeFelledEventEntity(treeId: 'tree-1', wood: 6)));
    expect(world.player.inventory.wood, 6);
    expect(world.trees, isEmpty);
    expect(world.player.activity, const IdleActivityEntity());
  });

  test('testWhenAnotherTreeStandsInTheWayThenReportsPlayerBlocked', () {
    // given
    final player = PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe));
    final world = WorldMock.make(
      player: player,
      trees: [
        TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 300, y: 100)),
        TreeEntityMock.mock.copyWith(id: 'in-the-way', position: const PositionEntity(x: 180, y: 100)),
      ],
    );
    world.orderChop('tree-1');

    // when
    final events = world.advanceFor(3000);

    // then
    expect(events, contains(const PlayerBlockedEventEntity()));
    expect(world.player.activity, const IdleActivityEntity());
  });

  test('testWhenTreeIsFelledThenPathIsFree', () {
    // given
    final world = _worldWithAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500 + Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

    // when
    world.movePlayerTo(const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000);

    // then
    expect(world.player.position, const PositionEntity(x: 300, y: 100));
  });
}
