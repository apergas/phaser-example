import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/tool_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenComparingToolsWithTheSameValuesThenTheyAreEqual', () {
    // given
    final first = ToolItemDataMock.axe(isOwned: true);
    final second = ToolItemDataMock.axe(isOwned: true);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenOwnershipChangesThenTheToolsAreNotEqual', () {
    // given
    final first = ToolItemDataMock.axe(isOwned: true);
    final second = ToolItemDataMock.axe(isOwned: false);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
}
