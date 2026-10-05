import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/resource_bar.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  double axeOpacity(WidgetTester tester) => tester.widget<Opacity>(find.byKey(ResourceBar.axeKey)).opacity;

  testWidgets('testWhenRenderedThenItShowsTheWoodAmount', (tester) async {
    // given
    const bar = ResourceBar(wood: 23, hasAxe: true);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text(Internationalize.forestWood), findsOneWidget);
    expect(find.text(Internationalize.forestAxe), findsOneWidget);
  });

  testWidgets('testWhenThePlayerHasNoAxeThenTheAxeIsDimmed', (tester) async {
    // given
    const bar = ResourceBar(wood: 0, hasAxe: false);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(axeOpacity(tester), 0.35);
  });

  testWidgets('testWhenThePlayerHasTheAxeThenTheAxeIsOpaque', (tester) async {
    // given
    const bar = ResourceBar(wood: 0, hasAxe: true);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(axeOpacity(tester), 1);
  });

  testWidgets('testWhenLabelsAreHiddenThenOnlyTheValueAndIconsAreShown', (tester) async {
    // given
    const bar = ResourceBar(wood: 7, hasAxe: true, showLabels: false);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(find.text('7'), findsOneWidget);
    expect(find.text(Internationalize.forestWood), findsNothing);
    expect(find.text(Internationalize.forestAxe), findsNothing);
  });
}
