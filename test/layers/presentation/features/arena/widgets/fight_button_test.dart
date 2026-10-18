import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/layers/presentation/features/arena/widgets/fight_button.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hud_button.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAFightCanStartThenTappingStartsIt', (tester) async {
    // given
    var fights = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: false, canFight: true, onFight: () => fights++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaFight));

    // then
    expect(fights, 1);
  });

  testWidgets('testWhenNoFightCanStartThenTheButtonIsDimmed', (tester) async {
    // given
    var fights = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: false, canFight: false, onFight: () => fights++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaFight));

    // then
    expect(fights, 0);
  });

  testWidgets('testWhenTheFightIsReplayingThenThereIsNoButton', (tester) async {
    // given
    var fights = 0;

    // when
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: true, canFight: false, onFight: () => fights++),
      ),
    );

    // then
    expect(find.text(Internationalize.arenaFight), findsNothing);
    expect(find.byType(HudButton), findsNothing);
    expect(fights, 0);
  });
}
