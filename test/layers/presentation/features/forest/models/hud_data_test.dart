import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/forest/hud_data_mock.dart';

void main() {
  test('testWhenComparingHudsWithEqualListsThenTheyAreEqual', () {
    // given
    final first = HudDataMock.mock;
    final second = HudDataMock.mockCopy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenTheWoodChangesThenTheHudsAreNotEqual', () {
    // given
    final first = HudDataMock.mock;
    final second = HudDataMock.withWood;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
}
