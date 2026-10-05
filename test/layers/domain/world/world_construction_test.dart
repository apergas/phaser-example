import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/game/construction_result_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/player/intent_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';

const _house = Blueprints.house;
void main() {
  test('testWhenConstructingWithoutEnoughWoodThenIsRejected', () {
    // given
    final world = WorldMock.make();

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 400, y: 400));

    // then
    expect(result, ConstructionResultEntityMock.notEnoughWood);
    expect(world.buildings, isEmpty);
  });

  test('testWhenSiteOverlapsTreePlayerOrEdgeThenIsBlockedWithoutCharging', () {
    // given
    final world = WorldMock.withFifteenWoodAndTreeAtSite();
    const blocked = ConstructionResultEntityMock.blocked;

    // when
    final overTree = world.orderConstruction(_house, const PositionEntity(x: 420, y: 400));
    final overPlayer = world.orderConstruction(_house, const PositionEntity(x: 110, y: 100));
    final overEdge = world.orderConstruction(_house, const PositionEntity(x: 10, y: 500));

    // then
    expect(overTree, blocked);
    expect(overPlayer, blocked);
    expect(overEdge, blocked);
    expect(world.player.inventory.wood, 15);
  });

  test('testWhenConstructingThenChargesWoodPlacesSiteAndWalksThere', () {
    // given
    final world = WorldMock.withSeventeenWood();

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // then
    expect(result, isA<ConstructionStartedEntity>());
    expect(world.player.inventory.wood, 2);
    expect(world.buildings.length, 1);
    expect(world.player.isMoving, isTrue);
  });

  test('testWhenReachingTheSiteThenBuildsFromTheFront', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // when
    world.advanceFor(3000);

    // then
    expect(
      (world.player.activity as WorkingActivityEntity).intent,
      IntentEntityMock.construct,
    );
    expect(world.player.position, const PositionEntity(x: 300, y: 150));
  });

  test('testWhenHammeringLongEnoughThenBuildingIsCompleted', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // when
    final events = world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);

    // then
    expect(events.whereType<BuildingHammeredEventEntity>().length, 8);
    expect(events, contains(GameEventEntityMock.buildingCompleted));
    expect(world.buildings.single.isComplete, isTrue);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenBuildingIsCompleteThenItBlocksMovement', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);
    for (final waypoint in const [PositionEntity(x: 200, y: 200), PositionEntity(x: 200, y: 100)]) {
      world.movePlayerTo(waypoint);
      world.advanceFor(3000);
    }

    // when
    world.movePlayerTo(const PositionEntity(x: 500, y: 100));
    world.advanceFor(5000);

    // then
    expect(world.player.position.x, lessThan(260));
  });
}
