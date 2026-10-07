import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/fight_button.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAFightCanStartThenTappingStartsIt', (tester) async {
    // given
    var fights = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: false, canFight: true, onFight: () => fights++, onSkip: () {}),
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
        child: FightButton(isReplaying: false, canFight: false, onFight: () => fights++, onSkip: () {}),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaFight));

    // then
    expect(fights, 0);
  });

  testWidgets('testWhenTheFightIsReplayingThenTheButtonSkipsIt', (tester) async {
    // given
    var skips = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: true, canFight: false, onFight: () {}, onSkip: () => skips++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaSkip));

    // then
    expect(skips, 1);
    expect(find.text(Internationalize.arenaFight), findsNothing);
  });
}
