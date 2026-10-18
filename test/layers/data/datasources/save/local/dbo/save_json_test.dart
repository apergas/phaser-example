import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_json.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_tree_dbo.dart';

import '../../../../../../mocks/data/datasources/save/save_json_mock.dart';

void main() {
  test('testWhenReadingADoubleThenIntegersAndDecimalsBecomeDoubles', () {
    // given
    const values = [3, 2.5, null];

    // when
    final doubles = values.map(readDouble).toList();

    // then
    expect(doubles, [3.0, 2.5, null]);
    expect(doubles.first, isA<double>());
  });

  test('testWhenReadingADoubleFromAStringThenItThrows', () {
    // given
    const value = SaveJsonMock.notJson;

    // when
    double? read() => readDouble(value);

    // then
    expect(read, throwsA(isA<TypeError>()));
  });

  test('testWhenReadingAnIntMapThenItKeepsKeysAndAmounts', () {
    // given
    const value = {'wood': 3, 'stone': 0};

    // when
    final map = readIntMap(value);

    // then
    expect(map, {'wood': 3, 'stone': 0});
    expect(readIntMap(null), isNull);
  });

  test('testWhenAnAmountOfTheIntMapIsNotAnIntegerThenItThrows', () {
    // given
    const value = {'wood': 1.5};

    // when
    Map<String, int>? read() => readIntMap(value);

    // then
    expect(read, throwsA(isA<TypeError>()));
  });

  test('testWhenReadingAStringListThenItCopiesTheItems', () {
    // given
    const value = ['a', 'b'];

    // when
    final list = readStringList(value);

    // then
    expect(list, ['a', 'b']);
    expect(readStringList(null), isNull);
  });

  test('testWhenAnItemOfTheStringListIsNotAStringThenItThrows', () {
    // given
    const value = ['a', 1];

    // when
    List<String>? read() => readStringList(value);

    // then
    expect(read, throwsA(isA<TypeError>()));
  });

  test('testWhenReadingAnObjectListThenEachItemGoesThroughFromJson', () {
    // given
    const value = [
      {'id': 'a'},
      {'id': 'b'},
    ];

    // when
    final list = readObjectList(value, SaveTreeDBO.fromJson);

    // then
    expect(list, [const SaveTreeDBO(id: 'a'), const SaveTreeDBO(id: 'b')]);
    expect(readObjectList(null, SaveTreeDBO.fromJson), isNull);
  });

  test('testWhenAnItemOfTheObjectListIsNotAMapThenItThrows', () {
    // given
    const value = ['a'];

    // when
    List<SaveTreeDBO>? read() => readObjectList(value, SaveTreeDBO.fromJson);

    // then
    expect(read, throwsA(isA<TypeError>()));
  });
}
