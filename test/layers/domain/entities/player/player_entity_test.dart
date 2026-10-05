import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/player/player_entity_mock.dart';

void main() {
  test('testWhenSpeedOrRadiusAreNotPositiveThenCreationFails', () {
    // given
    final zero = 0.0;

    // when
    Object zeroSpeed() => PlayerEntityMock.make(speed: zero);
    Object zeroRadius() => PlayerEntityMock.make(radius: zero);

    // then
    expect(zeroSpeed, throwsA(isA<AssertionError>()));
    expect(zeroRadius, throwsA(isA<AssertionError>()));
  });
}
