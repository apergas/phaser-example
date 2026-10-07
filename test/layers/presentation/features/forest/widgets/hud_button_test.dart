import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:rpg/layers/presentation/theme/images/custom_icons.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/widgets/widget_text_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenBadgeIsGivenThenItIsShownNextToTheLabel', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestQuests, badge: WidgetTextMock.badge, onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    expect(find.text(Internationalize.forestQuests), findsOneWidget);
    expect(find.text(WidgetTextMock.badge), findsOneWidget);
  });

  testWidgets('testWhenTappedThenOnPressedIsCalled', (tester) async {
    // given
    var taps = 0;
    await tester.pumpHud(
      Center(
        child: HudButton(label: Internationalize.forestBuild, onPressed: () => taps++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestBuild));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenOnPressedIsNullThenItIsDimmed', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestBuild);

    // when
    await tester.pumpHud(Center(child: button));
    await tester.tap(find.text(Internationalize.forestBuild));

    // then
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text(Internationalize.forestBuild), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.5);
  });

  testWidgets('testWhenBadgeIsGivenThenItUsesTabularFigures', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestQuests, badge: WidgetTextMock.badge, onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    expect(
      tester.widget<Text>(find.text(WidgetTextMock.badge)).style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('testWhenAnIconIsGivenThenItIsDrawnBeforeTheLabel', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestHero, icon: CustomIcons.hero, onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    final icon = find.byType(SvgPicture);
    expect(icon, findsOneWidget);
    expect(tester.getCenter(icon).dx, lessThan(tester.getCenter(find.text(Internationalize.forestHero)).dx));
  });
}
