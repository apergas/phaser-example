import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/widgets/custom-button/custom_button.dart';

void main() {
  testWidgets('testWhenTappingAnEnabledButtonThenItCallsOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(label: 'Construir aquí', onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text('Construir aquí'));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenTappingADisabledButtonThenItDoesNotCallOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(label: 'Construir aquí', isDisabled: true, onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text('Construir aquí'));

    // then
    expect(taps, 0);
  });
}
