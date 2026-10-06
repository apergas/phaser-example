import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/resource_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenComparingResourcesWithTheSameValuesThenTheyAreEqual', () {
    // given
    final first = ResourceItemDataMock.wood(6);
    final second = ResourceItemDataMock.wood(6);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenTheAmountChangesThenTheResourcesAreNotEqual', () {
    // given
    final first = ResourceItemDataMock.wood(6);
    final second = ResourceItemDataMock.wood(7);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
}
