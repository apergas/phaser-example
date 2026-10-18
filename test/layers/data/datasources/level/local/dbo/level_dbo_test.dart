import 'package:flutter_test/flutter_test.dart';

import '../../../../../../mocks/data/datasources/level/level_dbo_mock.dart';

void main() {
  test('testWhenTheLevelsHaveTheSameRocksThenTheyAreEqual', () {
    // given
    const level = LevelDBOMock.mockWithRocks;

    // when
    final copy = LevelDBOMock.mockWithRocks;

    // then
    expect(copy, level);
    expect(copy.hashCode, level.hashCode);
  });

  test('testWhenTheRocksDifferThenTheLevelsAreNotEqual', () {
    // given
    const level = LevelDBOMock.mockWithRocks;

    // when
    final others = [LevelDBOMock.mockWithOtherRocks, LevelDBOMock.mock];

    // then
    expect(others.where((other) => other == level), isEmpty);
  });
}
