import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/chop_result.dart';
import 'package:farming/core/config/constants/enum/deposit_result.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/building/building_entity.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/entities/player/intent_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  const tickMs = 50.0;

  World withDropOff(BuildingEntity building, {PlayerEntity player = PlayerEntityMock.carryingMixedLoad}) =>
      WorldMock.restored(player: player, buildings: [building]);

  List<GameEventEntity> depositAndWait(World world, String buildingId) {
    world.orderDeposit(buildingId);
    return world.advanceFor(4000, stepMs: tickMs);
  }

  test('testWhenTheTreeYieldsMoreThanFitsThenOnlyWhatFitsIsCarriedAndTheRestIsLost', () {
    // given
    final world = WorldMock.restored(player: PlayerEntityMock.withAxeAndNineWood, trees: [TreeEntityMock.oakOfEight]);
    world.orderChop('tree-1');

    // when
    final events = world.advanceFor(10000, stepMs: tickMs);

    // then
    expect(events, contains(GameEventEntityMock.treeFelledWithOneWood));
    expect(world.player.inventory.load, 10);
  });

  test('testWhenTheCarryIsFullThenChoppingIsRefusedAfterTheTreeAndTheAxeAreChecked', () {
    // given
    final full = WorldMock.restored(player: PlayerEntityMock.withAxeAndFullLoad, trees: [TreeEntityMock.mock]);
    final noAxe = WorldMock.restored(player: PlayerEntityMock.withFullLoadAndNoAxe, trees: [TreeEntityMock.mock]);

    // when
    final results = [full.orderChop('tree-99'), noAxe.orderChop('tree-1'), full.orderChop('tree-1')];

    // then
    expect(results, [ChopResult.unknownTree, ChopResult.noAxe, ChopResult.carryFull]);
    expect(full.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenDepositingAtAnUnknownBuildingThenItIsReported', () {
    // given
    final world = withDropOff(BuildingEntityMock.camp);

    // when
    final result = world.orderDeposit('building-99');

    // then
    expect(result, DepositResult.unknownBuilding);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenTheBuildingTakesNoDepositsOrIsUnfinishedThenItIsNotADropOff', () {
    // given
    final house = withDropOff(BuildingEntityMock.finishedHouse);
    final storehouseSite = withDropOff(BuildingEntityMock.storehouseSite);
    final quarrySite = withDropOff(BuildingEntityMock.quarrySite);

    // when
    final results = [
      house.orderDeposit('house'),
      storehouseSite.orderDeposit('storehouse'),
      quarrySite.orderDeposit('quarry'),
    ];

    // then
    expect(results, List.filled(3, DepositResult.notADropOff));
  });

  test('testWhenThePlayerOnlyCarriesGoldAndManaThenTheLoadIsEmpty', () {
    // given
    final world = withDropOff(BuildingEntityMock.camp, player: PlayerEntityMock.carryingOnlyGoldAndMana);

    // when
    final result = world.orderDeposit('camp');

    // then
    expect(result, DepositResult.emptyLoad);
  });

  test('testWhenDepositingAtTheCampThenThePlayerWalksInFrontAndUnloadsAfterFourHundredMilliseconds', () {
    // given
    final world = withDropOff(BuildingEntityMock.camp);

    // when
    final result = world.orderDeposit('camp');
    world.advanceFor(5000, stepMs: tickMs, until: () => world.player.activity is WorkingActivityEntity);
    final spot = world.player.position;
    final working = world.player.activity;
    final before = world.advance(399);
    final after = world.advance(1);

    // then
    expect(result, DepositResult.ok);
    expect(spot, const PositionEntity(x: 300, y: 140));
    expect(working, isA<WorkingActivityEntity>());
    expect((working as WorkingActivityEntity).intent, const DepositIntentEntity(buildingId: 'camp'));
    expect(before, isEmpty);
    expect(after, [GameEventEntityMock.depositedMixedLoadAtTheCamp]);
    expect(world.player.inventory, InventoryEntityMock.mixedLoadUnloaded);
    expect(world.stock, InventoryEntityMock.make(wood: 6, stone: 3));
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenDepositingAtAFinishedStorehouseThenTheWholeLoadIsStored', () {
    // given
    final world = withDropOff(BuildingEntityMock.storehouse);

    // when
    final events = depositAndWait(world, 'storehouse');

    // then
    expect(events.whereType<DepositedEventEntity>(), [GameEventEntityMock.depositedMixedLoadAtTheStorehouse]);
    expect(world.stock.amount(Resource.wood), 6);
    expect(world.player.inventory.load, 0);
  });

  test('testWhenDepositingAtAFinishedQuarryThenOnlyTheStoneIsStoredAndTheWoodStaysCarried', () {
    // given
    final world = withDropOff(BuildingEntityMock.quarry);

    // when
    final events = depositAndWait(world, 'quarry');

    // then
    expect(events.whereType<DepositedEventEntity>(), [GameEventEntityMock.depositedStoneAtTheQuarry]);
    expect(world.stock, InventoryEntityMock.make(stone: 3));
    expect(world.player.inventory.cargo, {Resource.wood: 6});
  });

  test('testWhenThePlayerOnlyCarriesWoodThenTheQuarryHasAnEmptyLoad', () {
    // given
    final world = withDropOff(
      BuildingEntityMock.quarry,
      player: PlayerEntityMock.withAxeAndNineWood,
    );

    // when
    final result = world.orderDeposit('quarry');

    // then
    expect(result, DepositResult.emptyLoad);
  });

  test('testWhenAQuarryIsNearThenDepositingStillTakesFourHundredMilliseconds', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.carryingMixedLoad,
      buildings: [
        BuildingEntityMock.camp,
        BuildingEntityMock.completed(
          BuildingEntityMock.quarry.blueprint,
          id: 'q',
          position: const PositionEntity(x: 300, y: 260),
        ),
      ],
    );
    world.orderDeposit('camp');
    world.advanceFor(5000, stepMs: tickMs, until: () => world.player.activity is WorkingActivityEntity);

    // when
    final before = world.advance(399);
    final after = world.advance(1);

    // then
    expect(before, isEmpty);
    expect(after, [GameEventEntityMock.depositedMixedLoadAtTheCamp]);
  });
}
