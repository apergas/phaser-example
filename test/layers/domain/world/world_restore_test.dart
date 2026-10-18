import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/game/construction_result_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/decoration/decoration_entity_mock.dart';
import '../../../mocks/domain/entities/item/ground_item_entity_mock.dart';
import '../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../mocks/domain/entities/tree/stump_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  test('testWhenRestoringAWorldThenEveryPieceOfStateComesBackInOrder', () {
    // given
    // when
    final world = SaveScenarioMock.everything();

    // then
    expect((world.width, world.height), (1600, 1200));
    expect(world.player, SaveScenarioMock.player);
    expect(world.trees, [TreeEntityMock.withThreeHitsTaken, TreeEntityMock.neighbour]);
    expect(world.stumps, [StumpEntityMock.elsewhereAlmostSapling, StumpEntityMock.sapling.copyWith(id: 'tree-9')]);
    expect(world.rocks, [RockEntityMock.onceHit]);
    expect(world.items, [GroundItemEntityMock.mock]);
    expect(world.decorations, [DecorationEntityMock.mock]);
    expect(world.buildings.map((building) => (building.id, building.hitsDone)), [
      ('camp', 1),
      ('building-1', 8),
      ('building-3', 4),
    ]);
    expect(world.hero, SaveScenarioMock.hero);
    expect(world.stats, SaveScenarioMock.stats);
    expect(world.stock, SaveScenarioMock.stock);
    expect(world.idCounters, SaveScenarioMock.idCounters);
  });

  test('testWhenBuildingAfterRestoringThenTheIdFollowsTheSavedNumbering', () {
    // given
    final world = SaveScenarioMock.everything();

    // when
    final result = world.orderConstruction(Blueprints.house, const PositionEntity(x: 1200, y: 900));

    // then
    expect((result as ConstructionStartedEntity).building.id, 'building-4');
    expect(world.idCounters, {'building': 4});
  });

  test('testWhenRestoringThenTheWorldKeepsItsOwnCopiesAndTheCountersCannotBeChangedFromOutside', () {
    // given
    final world = SaveScenarioMock.everything();

    // when
    world.buildings.clear();
    void changeCounter() => world.idCounters['building'] = 99;

    // then
    expect(world.buildings, hasLength(3));
    expect(changeCounter, throwsUnsupportedError);
    expect(world.buildings.first, BuildingEntityMock.camp);
  });
}
