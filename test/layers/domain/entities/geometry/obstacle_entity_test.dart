import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

void main() {
  test('testWhenRadiusIsNotPositiveThenCreationFails', () {
    // given
    final radius = 0.0;

    // when / then
    expect(
      () => ObstacleEntity(position: const PositionEntity(x: 0, y: 0), radius: radius),
      throwsA(isA<AssertionError>()),
    );
  });

  test('testWhenComparingObstaclesWithSameValuesThenTheyAreEqual', () {
    // given
    const obstacle = ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

    // when
    final isEqual = obstacle == const ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

    // then
    expect(isEqual, isTrue);
  });
}
