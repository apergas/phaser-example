import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

void main() {
  test('testWhenSpeedOrRadiusAreNotPositiveThenCreationFails', () {
    // given
    const position = PositionEntity(x: 0, y: 0);
    final zero = 0.0;

    // when / then
    expect(() => PlayerEntity(position: position, speed: zero, radius: 10), throwsA(isA<AssertionError>()));
    expect(() => PlayerEntity(position: position, speed: 100, radius: zero), throwsA(isA<AssertionError>()));
  });
}
