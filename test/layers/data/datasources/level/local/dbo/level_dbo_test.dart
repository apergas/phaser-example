import 'package:flutter_test/flutter_test.dart';

import '../../../../../../mocks/data/datasources/level/level_dbo_mock.dart';

void main() {
  test('testWhenTheLevelsHaveTheSameRocksAndBuildingsThenTheyAreEqual', () {
    // given
    const level = LevelDBOMock.mockWithRocksAndBuildings;

    // when
    final copy = LevelDBOMock.mockWithRocksAndBuildings;

    // then
    expect(copy, level);
    expect(copy.hashCode, level.hashCode);
  });

  test('testWhenTheRocksOrTheBuildingsDifferThenTheLevelsAreNotEqual', () {
    // given
    const level = LevelDBOMock.mockWithRocksAndBuildings;

    // when
    final others = [LevelDBOMock.mockWithOtherRocks, LevelDBOMock.mockWithOtherBuildings, LevelDBOMock.mock];

    // then
    expect(others.where((other) => other == level), isEmpty);
  });
}
