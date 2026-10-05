import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';

void main() {
  test('testWhenRadiusIsNotPositiveThenCreationFails', () {
    // given
    final radius = 0.0;

    // when
    Object act() => ObstacleEntityMock.make(radius: radius);

    // then
    expect(act, throwsA(isA<AssertionError>()));
  });

  test('testWhenComparingObstaclesWithSameValuesThenTheyAreEqual', () {
    // given
    const obstacle = ObstacleEntityMock.mock;

    // when
    final isEqual = obstacle == ObstacleEntityMock.make(radius: 10);
    final isDifferent = obstacle == ObstacleEntityMock.make(radius: 11);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
    expect(obstacle.hashCode, ObstacleEntityMock.make(radius: 10).hashCode);
  });
}
