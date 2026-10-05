import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/world_state.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';

WorldState _state({double width = 200, double height = 100}) => WorldState(
  width: width,
  height: height,
  player: PlayerEntityMock.mock,
  trees: [TreeEntityMock.mock],
  items: [],
  decorations: [],
);

void main() {
  test('testWhenClampingAPositionOutsideTheWorldThenKeepsTheMarginInside', () {
    // given
    final state = _state();

    // when
    final clamped = state.clamp(const PositionEntity(x: -50, y: 500), 8);

    // then
    expect(clamped, const PositionEntity(x: 8, y: 92));
  });

  test('testWhenAPositionIsTooCloseToTheEdgeThenItIsNotInside', () {
    // given
    final state = _state();

    // when
    final inside = state.isInside(const PositionEntity(x: 50, y: 50), 8);
    final nearEdge = state.isInside(const PositionEntity(x: 5, y: 50), 8);

    // then
    expect(inside, isTrue);
    expect(nearEdge, isFalse);
  });

  test('testWhenAskingForIdsThenTheyAreSequentialPerPrefix', () {
    // given
    final state = _state();

    // when
    final ids = [state.nextId('building'), state.nextId('building'), state.nextId('other')];

    // then
    expect(ids, ['building-1', 'building-2', 'other-1']);
  });

  test('testWhenTreesAndBuildingsStandThenTheyBlock', () {
    // given
    final state = _state(width: 1000, height: 1000);
    state.buildings[BuildingEntityMock.mock.id] = BuildingEntityMock.mock.copyWith(
      position: const PositionEntity(x: 500, y: 500),
    );

    // when
    final obstacles = state.obstacles();
    final blockedByTree = state.isBlocked(const PositionEntity(x: 200, y: 115), 8);
    final blockedByBuilding = state.isBlocked(const PositionEntity(x: 500, y: 545), 8);
    final free = state.isBlocked(const PositionEntity(x: 300, y: 300), 8);

    // then
    expect(obstacles.length, 2);
    expect(blockedByTree, isTrue);
    expect(blockedByBuilding, isTrue);
    expect(free, isFalse);
  });

  test('testWhenSizeIsNotPositiveThenCreationFails', () {
    // given
    final zero = 0.0;

    // when / then
    expect(() => _state(width: zero), throwsA(isA<AssertionError>()));
  });
}
