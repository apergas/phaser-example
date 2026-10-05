import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_row.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/quest_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  TextStyle titleStyleOf(WidgetTester tester, String title) => tester.widget<Text>(find.text(title)).style!;

  BoxDecoration rowDecorationOf(WidgetTester tester) {
    return tester.widget<DecoratedBox>(find.byKey(QuestRow.decorationKey)).decoration as BoxDecoration;
  }

  testWidgets('testWhenQuestIsDoneThenTitleIsStruckThroughAndCheckIsFilled', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.done);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final style = titleStyleOf(tester, QuestItemDataMock.done.title);
    expect(style.decoration, TextDecoration.lineThrough);
    expect(style.color, CustomColors.hudMuted);
    final check = tester.widget<Container>(find.byKey(QuestRow.checkKey)).decoration as BoxDecoration;
    expect((check.border! as Border).top.color, CustomColors.questDone);
    expect(find.text('Hecha'), findsOneWidget);
  });

  testWidgets('testWhenQuestIsCurrentThenRowIsHighlighted', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.current);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final decoration = rowDecorationOf(tester);
    expect(decoration.color, CustomColors.hudAccentSoft);
    expect((decoration.border! as Border).top.color, CustomColors.hudAccent);
    expect(find.text('6/15'), findsOneWidget);
  });

  testWidgets('testWhenQuestIsPendingThenTitleIsMutedAndRowIsNotHighlighted', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.pending);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final style = titleStyleOf(tester, QuestItemDataMock.pending.title);
    expect(style.color, CustomColors.hudMuted);
    expect(style.decoration, isNot(TextDecoration.lineThrough));
    expect(rowDecorationOf(tester).color, isNull);
  });

  testWidgets('testWhenRenderedThenTheProgressTextUsesTabularFigures', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.current);

    // when
    await tester.pumpHud(Center(child: row));

    // then
    final style = tester.widget<Text>(find.text(QuestItemDataMock.current.progressText)).style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
