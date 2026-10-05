import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenPathIsClearThenPlayerMoves', () {
    // given
    final world = WorldMock.make();
    world.movePlayerTo(const PositionEntity(x: 200, y: 100));

    // when
    world.advance(500);

    // then
    expect(world.player.position, const PositionEntity(x: 150, y: 100));
  });

  test('testWhenNextStepHitsATrunkThenPlayerStops', () {
    // given
    final world = WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 130, y: 100))]);
    world.movePlayerTo(const PositionEntity(x: 200, y: 100));

    // when
    world.advance(150);

    // then
    expect(world.player.position, const PositionEntity(x: 100, y: 100));
    expect(world.player.isMoving, isFalse);
  });

  test('testWhenDestinationIsOutsideTheWorldThenItIsClampedToTheEdge', () {
    // given
    final world = World(
      width: 200,
      height: 100,
      player: PlayerEntityMock.mock.copyWith(position: const PositionEntity(x: 50, y: 50)),
      trees: const [],
    );
    world.movePlayerTo(const PositionEntity(x: -50, y: 500));

    // when
    world.advanceFor(2000);

    // then
    expect(world.player.position, const PositionEntity(x: 8, y: 92));
  });
}
