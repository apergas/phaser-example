import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/mine_result.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

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

  test('testWhenTheCarryIsFullThenCarryFullIsReported', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxeAndFullLoad, rocks: [RockEntityMock.intact]);

    // when
    final result = world.orderMine('rock-1');

    // then
    expect(result, MineResult.carryFull);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenMiningThenTheRockIsHitEverySevenHundredFiftyMillisecondsAndBreaksOnTheEighth', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);

    // when
    final result = world.orderMine('rock-1');
    final times = hitTimes(world);

    // then
    expect(result, MineResult.ok);
    expect(times, hasLength(8));
    expect(gaps(times).toSet(), {750.0});
  });

  test('testWhenTheEighthHitLandsThenTheRockBreaksIntoEightStoneThatIsCarried', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    final events = world.advanceFor(12000, stepMs: tickMs);

    // then
    final rockEvents = events.where((event) => event is RockHitEventEntity || event is RockBrokenEventEntity).toList();
    expect(rockEvents.sublist(rockEvents.length - 2), [GameEventEntityMock.rockHit, GameEventEntityMock.rockBroken]);
    expect(world.player.inventory.amount(Resource.stone), 8);
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

  test('testWhenTheRockBreaksWithLittleRoomLeftThenOnlyWhatFitsIsCarried', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withPickaxeAndSixWood, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    final events = world.advanceFor(12000, stepMs: tickMs);

    // then
    expect(events, contains(GameEventEntityMock.rockBrokenWithFourStone));
    expect(world.player.inventory.load, 10);
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

  test('testWhenAFinishedQuarryIsNearTheRockThenTheHitsComeEveryFiveHundredTwentyFiveMilliseconds', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.withPickaxe,
      rocks: [RockEntityMock.intact],
      buildings: [BuildingEntityMock.completed(Blueprints.quarry, position: RockEntityMock.quarryNearTheRock)],
    );
    world.orderMine('rock-1');

    // when
    final times = hitTimes(world, untilMs: 8000);

    // then
    expect(gaps(times).toSet(), {525.0});
  });

  test('testWhenTheQuarryIsTooFarOrUnfinishedThenTheHitsStayAtSevenHundredFiftyMilliseconds', () {
    // given
    World withQuarry(bool complete, {required bool near}) => WorldMock.restored(
      player: PlayerEntityMock.withPickaxe,
      rocks: [RockEntityMock.intact],
      buildings: [
        complete
            ? BuildingEntityMock.completed(
                Blueprints.quarry,
                position: near ? RockEntityMock.quarryNearTheRock : RockEntityMock.quarryAtTheBoostRange,
              )
            : BuildingEntityMock.site(Blueprints.quarry, position: RockEntityMock.quarryNearTheRock),
      ],
    );
    final far = withQuarry(true, near: false)..orderMine('rock-1');
    final site = withQuarry(false, near: true)..orderMine('rock-1');

    // when
    final farGaps = gaps(hitTimes(far)).toSet();
    final siteGaps = gaps(hitTimes(site)).toSet();

    // then
    expect(farGaps, {750.0});
    expect(siteGaps, {750.0});
  });

  test('testWhenAQuarryBoostsMiningThenTheWorkProgressUsesTheShorterInterval', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.withPickaxe,
      rocks: [RockEntityMock.intact],
      buildings: [BuildingEntityMock.completed(Blueprints.quarry, position: RockEntityMock.quarryNearTheRock)],
    );
    world.orderMine('rock-1');
    hitTimes(world, untilMs: 3000);

    // when
    final elapsed = (world.player.activity as WorkingActivityEntity).elapsedMs;

    // then
    expect(world.workProgress, closeTo(elapsed / 525, 1e-9));
  });

  test('testWhenThePickaxeIsUpgradedThenTheRockBreaksOnTheFifthHit', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withIronPickaxe, rocks: [RockEntityMock.intact]);
    world.orderMine('rock-1');

    // when
    final times = hitTimes(world);

    // then
    expect(times, hasLength(5));
    expect(gaps(times).toSet(), {750.0});
    expect(world.player.inventory.amount(Resource.stone), 8);
  });
}
