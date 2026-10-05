import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';

import '../../../../../helpers/hud_test_app.dart';

void main() {
  testWidgets('testWhenBadgeIsGivenThenItIsShownNextToTheLabel', (tester) async {
    // given
    final button = HudButton(label: 'Misiones', badge: '1/3', onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    expect(find.text('Misiones'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('testWhenTappedThenOnPressedIsCalled', (tester) async {
    // given
    var taps = 0;
    await tester.pumpHud(
      Center(
        child: HudButton(label: 'Construir', onPressed: () => taps++),
      ),
    );

    // when
    await tester.tap(find.text('Construir'));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenOnPressedIsNullThenItIsDimmed', (tester) async {
    // given
    const button = HudButton(label: 'Construir');

    // when
    await tester.pumpHud(const Center(child: button));
    await tester.tap(find.text('Construir'));

    // then
    final opacity = tester.widget<Opacity>(find.ancestor(of: find.text('Construir'), matching: find.byType(Opacity)));
    expect(opacity.opacity, 0.5);
  });
}
