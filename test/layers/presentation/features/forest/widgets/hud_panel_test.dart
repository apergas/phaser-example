import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_panel.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/widgets/widget_text_mock.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) {
    return tester.widget<DecoratedBox>(find.byKey(HudPanel.decorationKey)).decoration as BoxDecoration;
  }

  testWidgets('testWhenRenderedThenItHasTheHudBackgroundAndBorder', (tester) async {
    // given
    const panel = HudPanel(child: Text(WidgetTextMock.content));

    // when
    await tester.pumpHud(const Center(child: panel));

    // then
    final decoration = decorationOf(tester);
    expect(decoration.color, CustomColors.hudBackground);
    expect((decoration.border! as Border).top.color, CustomColors.hudBorder);
    expect((decoration.border! as Border).top.width, 2);
    expect(find.text(WidgetTextMock.content), findsOneWidget);
  });

  testWidgets('testWhenHighlightedThenTheBorderUsesTheAccent', (tester) async {
    // given
    const panel = HudPanel(isHighlighted: true, child: Text(WidgetTextMock.content));

    // when
    await tester.pumpHud(const Center(child: panel));

    // then
    expect((decorationOf(tester).border! as Border).top.color, CustomColors.hudAccent);
  });
}
