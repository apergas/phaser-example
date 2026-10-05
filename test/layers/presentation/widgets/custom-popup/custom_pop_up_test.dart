import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';
import 'package:rpg/layers/presentation/widgets/custom-popup/custom_pop_up.dart';

void main() {
  testWidgets('testWhenTextColorIsNullThenTitleAndMessageUseHudText', (tester) async {
    // given
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomPopUp(title: 'Titulo', message: 'Mensaje', actions: [], textColor: null),
      ),
    );

    // when
    final title = tester.widget<Text>(find.text('Titulo'));
    final message = tester.widget<Text>(find.text('Mensaje'));

    // then
    expect(title.style!.color, CustomColors.hudText);
    expect(message.style!.color, CustomColors.hudText);
  });

  testWidgets('testWhenTextColorIsGivenThenTitleUsesIt', (tester) async {
    // given
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomPopUp(title: 'Titulo', actions: [], textColor: CustomColors.error),
      ),
    );

    // when
    final title = tester.widget<Text>(find.text('Titulo'));

    // then
    expect(title.style!.color, CustomColors.error);
  });
}
