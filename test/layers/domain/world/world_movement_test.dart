import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

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
    final world = WorldMock.withTreeBlockingPath();
    world.movePlayerTo(const PositionEntity(x: 200, y: 100));

    // when
    world.advance(150);

    // then
    expect(world.player.position, const PositionEntity(x: 100, y: 100));
    expect(world.player.isMoving, isFalse);
  });

  test('testWhenDestinationIsOutsideTheWorldThenItIsClampedToTheEdge', () {
    // given
    final world = WorldMock.small();
    world.movePlayerTo(const PositionEntity(x: -50, y: 500));

    // when
    world.advanceFor(2000);

    // then
    expect(world.player.position, const PositionEntity(x: 8, y: 92));
  });
}
