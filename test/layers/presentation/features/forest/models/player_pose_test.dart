import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/forest/player_pose_mock.dart';

void main() {
  test('testWhenComparingPosesWithTheSameValuesThenTheyAreEqual', () {
    // given
    final first = PlayerPoseMock.work;
    final second = PlayerPoseMock.workCopy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenComparingPosesOfDifferentKindsThenTheyAreNotEqual', () {
    // given
    final idle = PlayerPoseMock.idle;
    final walk = PlayerPoseMock.walk;

    // when
    final isEqual = idle == walk;

    // then
    expect(isEqual, isFalse);
  });
}
