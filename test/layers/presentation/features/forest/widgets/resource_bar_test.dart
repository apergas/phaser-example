import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/presentation/features/forest/widgets/resource_bar.dart';
import 'package:farming/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/carry_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/resource_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/tool_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  double axeOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.byKey(ResourceBar.toolKey(ToolKind.axe))).opacity;

  Color carryColor(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: find.byKey(ResourceBar.carryKey), matching: find.byType(Text)))
      .style!
      .color!;

  testWidgets('testWhenRenderedThenItShowsTheStockTheCarryAndEveryTool', (tester) async {
    // given
    final bar = ResourceBar(
      stock: [ResourceItemDataMock.wood(23)],
      carry: CarryItemDataMock.sevenOfTen,
      tools: [ToolItemDataMock.axe(isOwned: true)],
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text(Internationalize.forestStock), findsOneWidget);
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsOneWidget);
    expect(find.text(CarryItemDataMock.sevenOfTen.text), findsOneWidget);
    expect(find.text(Internationalize.forestTool(tool: ToolKind.axe)), findsOneWidget);
  });

  testWidgets('testWhenThePlayerHasNoAxeThenTheAxeIsDimmed', (tester) async {
    // given
    final bar = ResourceBar(
      stock: [ResourceItemDataMock.wood(0)],
      carry: CarryItemDataMock.empty,
      tools: [ToolItemDataMock.axe(isOwned: false)],
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(axeOpacity(tester), 0.35);
  });

  testWidgets('testWhenThePlayerHasTheAxeThenTheAxeIsOpaque', (tester) async {
    // given
    final bar = ResourceBar(
      stock: [ResourceItemDataMock.wood(0)],
      carry: CarryItemDataMock.empty,
      tools: [ToolItemDataMock.axe(isOwned: true)],
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(axeOpacity(tester), 1);
  });

  testWidgets('testWhenLabelsAreHiddenThenOnlyTheValuesTheCarryAndIconsAreShown', (tester) async {
    // given
    final bar = ResourceBar(
      stock: [ResourceItemDataMock.wood(7)],
      carry: CarryItemDataMock.empty,
      tools: [ToolItemDataMock.axe(isOwned: true)],
      showLabels: false,
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(find.text('7'), findsOneWidget);
    expect(find.text(CarryItemDataMock.empty.text), findsOneWidget);
    expect(find.text(Internationalize.forestStock), findsNothing);
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsNothing);
    expect(find.text(Internationalize.forestTool(tool: ToolKind.axe)), findsNothing);
  });

  testWidgets('testWhenRenderedThenTheWoodAmountUsesTabularFigures', (tester) async {
    // given
    final bar = ResourceBar(
      stock: [ResourceItemDataMock.wood(23)],
      carry: CarryItemDataMock.empty,
      tools: [ToolItemDataMock.axe(isOwned: true)],
    );

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(tester.widget<Text>(find.text('23')).style!.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('testWhenTheCarryIsNotFullThenItUsesTheTextColour', (tester) async {
    // given
    final bar = ResourceBar(stock: const [], carry: CarryItemDataMock.sevenOfTen, tools: const []);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(carryColor(tester), CustomColors.hudText);
  });

  testWidgets('testWhenTheCarryIsFullThenItUsesTheWarningColour', (tester) async {
    // given
    final bar = ResourceBar(stock: const [], carry: CarryItemDataMock.full, tools: const []);

    // when
    await tester.pumpHud(Center(child: bar));

    // then
    expect(carryColor(tester), CustomColors.hudWarning);
  });
}
