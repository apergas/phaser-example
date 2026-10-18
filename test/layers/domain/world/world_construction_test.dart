import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/world/extensions/stock_rules.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/resume_construction_result.dart';
import 'package:farming/layers/domain/entities/game/construction_result_entity.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/game/construction_result_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/player/intent_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/funds_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';
import '../../../mocks/domain/entities/player/activity_entity_mock.dart';

const _house = Blueprints.house;
void main() {
  test('testWhenConstructingWithoutEnoughResourcesThenIsRejected', () {
    // given
    final world = WorldMock.make();

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 400, y: 400));

    // then
    expect(result, ConstructionResultEntityMock.notEnoughResources);
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
    expect(world.stock.amount(Resource.wood), 15);
  });

  test('testWhenConstructingThenChargesWoodPlacesSiteAndWalksThere', () {
    // given
    final world = WorldMock.withSeventeenWood();

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // then
    expect(result, isA<ConstructionStartedEntity>());
    expect(world.stock.amount(Resource.wood), 2);
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
  test('testWhenLeavingASiteAndResumingThenKeepsProgressAndFinishesWithoutCharging', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * 3);
    world.movePlayerTo(const PositionEntity(x: 200, y: 250));
    world.advanceFor(3000);
    final hitsBefore = world.buildings.single.hitsDone;

    // when
    final result = world.orderResumeConstruction('building-1');
    final events = world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);

    // then
    expect(hitsBefore, inInclusiveRange(1, _house.hitsToBuild - 1));
    expect(result, ResumeConstructionResult.ok);
    expect(events.whereType<BuildingHammeredEventEntity>().length, _house.hitsToBuild - hitsBefore);
    expect(world.buildings.single.isComplete, isTrue);
    expect(world.stock.amount(Resource.wood), 2);
  });

  test('testWhenResumingAnUnknownBuildingThenReturnsUnknownBuildingAndStaysIdle', () {
    // given
    final world = WorldMock.withSeventeenWood();

    // when
    final result = world.orderResumeConstruction('building-99');

    // then
    expect(result, ResumeConstructionResult.unknownBuilding);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenResumingACompleteBuildingThenReturnsAlreadyComplete', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);

    // when
    final result = world.orderResumeConstruction('building-1');

    // then
    expect(result, ResumeConstructionResult.alreadyComplete);
    expect(world.player.activity, ActivityEntityMock.idle);
  });

  test('testWhenTheStockIsShortAndTheSiteIsBlockedThenTheStockIsReportedFirst', () {
    // given
    final world = WorldMock.make(trees: [TreeEntityMock.atSite]);

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 420, y: 400));

    // then
    expect(result, ConstructionResultEntityMock.notEnoughResources);
  });

  test('testWhenConstructingThenItIsPaidFromTheStock', () {
    // given
    final world = WorldMock.withStock(FundsMock.seventeenWood);

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // then
    expect(result, isA<ConstructionStartedEntity>());
    expect(world.stock.amount(Resource.wood), 2);
  });

  test('testWhenTryingToPlaceTheCampThenItIsBlocked', () {
    // given
    final world = WorldMock.withSeventeenWood();

    // when
    final rejection = world.placementRejection(Blueprints.camp, const PositionEntity(x: 300, y: 100));
    final result = world.orderConstruction(Blueprints.camp, const PositionEntity(x: 300, y: 100));

    // then
    expect(rejection, ConstructionRejection.blocked);
    expect(result, ConstructionResultEntityMock.blocked);
    expect(world.buildings, isEmpty);
  });
}
