import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenComparingPanelsWithEqualRowsThenTheyAreEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.newHeroCopy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenAGearRowChangesThenThePanelsAreNotEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.readyToBuySword;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenASkillChangesThenThePanelsAreNotEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.readyToLearnDoubleStrike;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
    expect(first.rows, second.rows);
  });
}
