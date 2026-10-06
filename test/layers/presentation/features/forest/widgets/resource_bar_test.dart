import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/resource_bar.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/resource_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/tool_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  double axeOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.byKey(ResourceBar.toolKey(ToolKind.axe))).opacity;

  testWidgets('testWhenRenderedThenItShowsEveryResourceAndTool', (tester) async {
    // given
    final bar = ResourceBar(resources: [ResourceItemDataMock.wood(23)], tools: [ToolItemDataMock.axe(isOwned: true)]);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsOneWidget);
    expect(find.text(Internationalize.forestTool(tool: ToolKind.axe)), findsOneWidget);
  });

  testWidgets('testWhenThePlayerHasNoAxeThenTheAxeIsDimmed', (tester) async {
    // given
    final bar = ResourceBar(resources: [ResourceItemDataMock.wood(0)], tools: [ToolItemDataMock.axe(isOwned: false)]);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(axeOpacity(tester), 0.35);
  });

  testWidgets('testWhenThePlayerHasTheAxeThenTheAxeIsOpaque', (tester) async {
    // given
    final bar = ResourceBar(resources: [ResourceItemDataMock.wood(0)], tools: [ToolItemDataMock.axe(isOwned: true)]);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(axeOpacity(tester), 1);
  });

  testWidgets('testWhenLabelsAreHiddenThenOnlyTheValueAndIconsAreShown', (tester) async {
    // given
    final bar = ResourceBar(
      resources: [ResourceItemDataMock.wood(7)],
      tools: [ToolItemDataMock.axe(isOwned: true)],
      showLabels: false,
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(find.text('7'), findsOneWidget);
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsNothing);
    expect(find.text(Internationalize.forestTool(tool: ToolKind.axe)), findsNothing);
  });

  testWidgets('testWhenRenderedThenTheWoodAmountUsesTabularFigures', (tester) async {
    // given
    final bar = ResourceBar(resources: [ResourceItemDataMock.wood(23)], tools: [ToolItemDataMock.axe(isOwned: true)]);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(tester.widget<Text>(find.text('23')).style!.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
