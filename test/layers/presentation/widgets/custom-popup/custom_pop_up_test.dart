import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';
import 'package:rpg/layers/presentation/widgets/custom-popup/custom_pop_up.dart';

import '../../../../mocks/presentation/widgets/widget_text_mock.dart';

void main() {
  testWidgets('testWhenTextColorIsNullThenTitleAndMessageUseHudText', (tester) async {
    // given
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomPopUp(
          title: WidgetTextMock.popUpTitle,
          message: WidgetTextMock.popUpMessage,
          actions: [],
          textColor: null,
        ),
      ),
    );

    // when
    final title = tester.widget<Text>(find.text(WidgetTextMock.popUpTitle));
    final message = tester.widget<Text>(find.text(WidgetTextMock.popUpMessage));

    // then
    expect(title.style!.color, CustomColors.hudText);
    expect(message.style!.color, CustomColors.hudText);
  });

  testWidgets('testWhenTextColorIsGivenThenTitleUsesIt', (tester) async {
    // given
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomPopUp(title: WidgetTextMock.popUpTitle, actions: [], textColor: CustomColors.error),
      ),
    );

    // when
    final title = tester.widget<Text>(find.text(WidgetTextMock.popUpTitle));

    // then
    expect(title.style!.color, CustomColors.error);
  });
}
