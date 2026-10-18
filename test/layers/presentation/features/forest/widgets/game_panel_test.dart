import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/layers/presentation/features/forest/widgets/game_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  Future<List<String>> pumpPanel(WidgetTester tester) async {
    final calls = <String>[];
    await tester.pumpHud(
      Center(
        child: GamePanel(onSave: () => calls.add('save'), onNewGame: () => calls.add('newGame')),
      ),
    );
    return calls;
  }

  testWidgets('testWhenShownThenTheTitleSaveAndNewGameAreThere', (tester) async {
    // given
    // when
    await pumpPanel(tester);

    // then
    expect(find.text(Internationalize.forestGame.toUpperCase()), findsOneWidget);
    expect(find.text(Internationalize.forestGameSave), findsOneWidget);
    expect(find.text(Internationalize.forestGameNewGame), findsOneWidget);
  });

  testWidgets('testWhenSaveIsTappedThenOnSaveIsCalled', (tester) async {
    // given
    final calls = await pumpPanel(tester);

    // when
    await tester.tap(find.byKey(GamePanel.saveKey));

    // then
    expect(calls, ['save']);
  });

  testWidgets('testWhenNewGameIsTappedThenItAsksForConfirmationWithoutStarting', (tester) async {
    // given
    final calls = await pumpPanel(tester);

    // when
    await tester.tap(find.byKey(GamePanel.newGameKey));
    await tester.pump();

    // then
    expect(calls, isEmpty);
    expect(find.text(Internationalize.forestGameNewGameConfirm), findsOneWidget);
    expect(find.byKey(GamePanel.confirmKey), findsOneWidget);
    expect(find.byKey(GamePanel.saveKey), findsNothing);
  });

  testWidgets('testWhenTheConfirmationIsCancelledThenTheActionsAreBack', (tester) async {
    // given
    final calls = await pumpPanel(tester);
    await tester.tap(find.byKey(GamePanel.newGameKey));
    await tester.pump();

    // when
    await tester.tap(find.byKey(GamePanel.cancelKey));
    await tester.pump();

    // then
    expect(calls, isEmpty);
    expect(find.byKey(GamePanel.saveKey), findsOneWidget);
    expect(find.text(Internationalize.forestGameNewGameConfirm), findsNothing);
  });

  testWidgets('testWhenTheNewGameIsConfirmedThenOnNewGameIsCalled', (tester) async {
    // given
    final calls = await pumpPanel(tester);
    await tester.tap(find.byKey(GamePanel.newGameKey));
    await tester.pump();

    // when
    await tester.tap(find.byKey(GamePanel.confirmKey));

    // then
    expect(calls, ['newGame']);
  });
}
