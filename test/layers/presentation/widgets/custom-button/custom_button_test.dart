import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/widgets/custom-button/custom_button.dart';

import '../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTappingAnEnabledButtonThenItCallsOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(label: Internationalize.forestPlacementConfirm, onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenTappingADisabledButtonThenItDoesNotCallOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(label: Internationalize.forestPlacementConfirm, isDisabled: true, onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));

    // then
    expect(taps, 0);
  });
}
