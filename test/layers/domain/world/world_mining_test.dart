import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/mine_result.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';
import '../../../mocks/domain/entities/stock/stock_entity_mock.dart';

void main() {
  const tickMs = 50.0;

  List<double> hitTimes(World world, {double untilMs = 12000, double stepMs = 25}) {
    final times = <double>[];
    var clock = 0.0;
    while (clock < untilMs) {
      clock += stepMs;
      if (world.advance(stepMs).any((event) => event is RockHitEventEntity)) times.add(clock);
    }
    return times;
  }

  List<double> gaps(List<double> times) => [for (var i = 1; i < times.length; i++) times[i] - times[i - 1]];

  test('testWhenMiningAnUnknownRockWithoutAPickaxeThenTheUnknownRockIsReportedAndThePlayerStays', () {
    // given
    final world = WorldMock.restored(rocks: [RockEntityMock.intact]);

    // when
    final result = world.orderMine('rock-99');

    // then
    expect(result, MineResult.unknownRock);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenMiningWithoutAPickaxeThenNoPickaxeIsReportedAndThePlayerStays', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withAxe, rocks: [RockEntityMock.intact]);

    // when
    final result = world.orderMine('rock-1');
    world.advanceFor(1000);

    // then
    expect(result, MineResult.noPickaxe);
    expect(world.player.position, PlayerEntityMock.withAxe.position);
  });

  test('testWhenMiningThenTheRockIsHitAtTheChoppingPaceAndBreaksOnTheSeventh', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);

    // when
    final result = world.orderMine('rock-1');
    final times = hitTimes(world);

    // then
    expect(result, MineResult.ok);
    expect(times, hasLength(7));
    expect(gaps(times).toSet(), {Rules.chopIntervalMs});
  });

  test('testWhenTheSeventhHitLandsThenTheRockBreaksIntoEightStoneThatGoesToTheStock', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    final events = world.advanceFor(12000, stepMs: tickMs);

    // then
    final rockEvents = events.where((event) => event is RockHitEventEntity || event is RockBrokenEventEntity).toList();
    expect(rockEvents.sublist(rockEvents.length - 2), [GameEventEntityMock.rockHit, GameEventEntityMock.rockBroken]);
    expect(world.stock, StockEntityMock.eightStone);
    expect(world.player.inventory, PlayerEntityMock.withPickaxe.inventory);
    expect(world.rocks, isEmpty);
    expect(world.obstacles, isNot(contains(ObstacleEntityMock.rock)));
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenTheRockStandsThenItIsAnObstacle', () {
    // given
    final world = WorldMock.restored(rocks: [RockEntityMock.intact]);

    // when
    final obstacles = world.obstacles;

    // then
    expect(obstacles, [ObstacleEntityMock.rock]);
  });

  test('testWhenTheStockAlreadyHoldsALotThenTheWholeStoneOfTheRockIsStored', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.withPickaxe,
      rocks: [RockEntityMock.intact],
      stock: StockEntityMock.make(wood: 40),
    );
    world.orderMine('rock-1');

    // when
    final events = world.advanceFor(12000, stepMs: tickMs);

    // then
    expect(events, contains(GameEventEntityMock.rockBroken));
    expect(world.stock, StockEntityMock.make(wood: 40, stone: 8));
  });

  test('testWhenMiningTheSameRockAgainThenTheSwingStartsOver', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');
    hitTimes(world, untilMs: 3000);
    final before = (world.player.activity as WorkingActivityEntity).elapsedMs;

    // when
    world.orderMine('rock-1');

    // then
    expect(before, greaterThan(0));
    expect((world.player.activity as WorkingActivityEntity).elapsedMs, 0);
  });

  test('testWhenThePickaxeIsUpgradedThenTheRockBreaksOnTheFifthHit', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withIronPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    final times = hitTimes(world);

    // then
    expect(times, hasLength(5));
    expect(gaps(times).toSet(), {Rules.chopIntervalMs});
    expect(world.stock, StockEntityMock.eightStone);
  });
}
