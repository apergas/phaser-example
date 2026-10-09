import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/quest_line.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_panel.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_row.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/quest_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenRenderedThenItShowsTheTitleAndOneRowPerQuest', (tester) async {
    // given
    final panel = QuestPanel(quests: QuestItemDataMock.all);

    // when
    await tester.pumpHud(Center(child: panel));

    // then
    expect(find.text(Internationalize.forestQuests.toUpperCase()), findsOneWidget);
    expect(find.byType(QuestRow), findsNWidgets(3));
  });

  testWidgets('testWhenBothLinesHaveQuestsThenEachIsListedUnderItsOwnHeading', (tester) async {
    // given
    final panel = QuestPanel(quests: QuestItemDataMock.withBothLines);

    // when
    await tester.pumpHud(Center(child: panel));

    // then
    expect(find.text(Internationalize.forestQuestLine(line: QuestLine.village)), findsOneWidget);
    expect(find.text(Internationalize.forestQuestLine(line: QuestLine.hero)), findsOneWidget);
    expect(find.byType(QuestRow), findsNWidgets(4));
    expect(
      tester.getTopLeft(find.text(Internationalize.forestQuestLine(line: QuestLine.hero))).dy,
      greaterThan(tester.getTopLeft(find.text(Internationalize.forestQuestTitle(id: QuestId.buildHouse))).dy),
    );
  });
}
