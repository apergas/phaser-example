import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/world/world_state_mock.dart';

void main() {
  test('testWhenClampingAPositionOutsideTheWorldThenKeepsTheMarginInside', () {
    // given
    final state = WorldStateMock.make();

    // when
    final clamped = state.clamp(const PositionEntity(x: -50, y: 500), 8);

    // then
    expect(clamped, const PositionEntity(x: 8, y: 92));
  });

  test('testWhenAPositionIsTooCloseToTheEdgeThenItIsNotInside', () {
    // given
    final state = WorldStateMock.make();

    // when
    final inside = state.isInside(const PositionEntity(x: 50, y: 50), 8);
    final nearEdge = state.isInside(const PositionEntity(x: 5, y: 50), 8);

    // then
    expect(inside, isTrue);
    expect(nearEdge, isFalse);
  });

  test('testWhenAskingForIdsThenTheyAreSequentialPerPrefix', () {
    // given
    final state = WorldStateMock.make();

    // when
    final ids = [state.nextId('building'), state.nextId('building'), state.nextId('other')];

    // then
    expect(ids, ['building-1', 'building-2', 'other-1']);
  });

  test('testWhenTreesAndBuildingsStandThenTheyBlock', () {
    // given
    final state = WorldStateMock.make(width: 1000, height: 1000);
    state.buildings[BuildingEntityMock.mock.id] = BuildingEntityMock.farCorner;

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

    // when
    Object act() => WorldStateMock.make(width: zero);

    // then
    expect(act, throwsA(isA<AssertionError>()));
  });
}
