import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheHeroWonThenTheGoldIsShownWithoutRetry', (tester) async {
    // given
    final result = ArenaResultDataMock.victoryTenGold;

    // when
    await tester.pumpHud(
      Center(
        child: ResultPanel(result: result, onRetry: () {}),
      ),
    );

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
    expect(find.text(Internationalize.arenaRetry), findsNothing);
  });

  testWidgets('testWhenTheHeroLostThenTheAdviceAndRetryAreShown', (tester) async {
    // given
    var retries = 0;
    final result = ArenaResultDataMock.defeatNeedAttack;
    await tester.pumpHud(
      Center(
        child: ResultPanel(result: result, onRetry: () => retries++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaRetry));

    // then
    expect(find.text(Internationalize.arenaDefeat), findsOneWidget);
    expect(find.text(result.detail), findsOneWidget);
    expect(retries, 1);
  });
}
