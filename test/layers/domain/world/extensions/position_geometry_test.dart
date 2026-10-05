import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/position_geometry.dart';

void main() {
  test('testWhenMeasuringDistanceThenReturnsEuclideanDistance', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final distance = origin.distanceTo(const PositionEntity(x: 3, y: 4));

    // then
    expect(distance, 5.0);
  });

  test('testWhenMovingTowardsTargetThenAdvancesByStep', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final moved = origin.moveTowards(const PositionEntity(x: 10, y: 0), 4);

    // then
    expect(moved, const PositionEntity(x: 4, y: 0));
  });

  test('testWhenStepWouldOvershootThenSnapsToTarget', () {
    // given
    const target = PositionEntity(x: 10, y: 0);

    // when
    final moved = const PositionEntity(x: 8, y: 0).moveTowards(target, 5);

    // then
    expect(moved, same(target));
  });

  test('testWhenAskingPointAtDistanceThenFollowsDirection', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final point = origin.pointAtDistance(5, const PositionEntity(x: 30, y: 40));

    // then
    expect(point, const PositionEntity(x: 3, y: 4));
  });

  test('testWhenBothPositionsCoincideThenPointIsBelow', () {
    // given
    const position = PositionEntity(x: 1, y: 1);

    // when
    final point = position.pointAtDistance(5, const PositionEntity(x: 1, y: 1));

    // then
    expect(point, const PositionEntity(x: 1, y: 6));
  });
}
