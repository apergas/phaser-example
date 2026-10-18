import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:farming/layers/presentation/features/forest/widgets/skill_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/skill_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheSkillCanBeLearnedThenTappingLearnCallsOnLearn', (tester) async {
    // given
    var learns = 0;
    final item = SkillItemDataMock.doubleStrikeAvailable;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () => learns++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));

    // then
    expect(learns, 1);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.description), findsOneWidget);
    expect(find.text(item.costText!), findsOneWidget);
  });

  testWidgets('testWhenTheTowerIsMissingThenLearnIsDisabledAndTheReasonIsShown', (tester) async {
    // given
    var learns = 0;
    final item = SkillItemDataMock.needsTower(SkillId.dodge);

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () => learns++),
        ),
      ),
    );
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.dodge)));

    // then
    expect(learns, 0);
    expect(tester.widget<HudButton>(find.byKey(SkillTile.learnKey(SkillId.dodge))).onPressed, isNull);
    expect(find.text(item.reasonText!), findsOneWidget);
  });

  testWidgets('testWhenTheSkillIsNotLearnedThenThereIsNoLevelAndTheButtonSaysLearn', (tester) async {
    // given
    final item = SkillItemDataMock.doubleStrikeAvailable;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(width: 340, child: SkillTile(item: item)),
      ),
    );

    // then
    expect(find.text(Internationalize.forestHeroLearn), findsOneWidget);
    expect(find.text(Internationalize.forestHeroSkillLevel(level: 1, max: 3)), findsNothing);
    expect(find.text(Internationalize.forestHeroSkillMax), findsNothing);
  });

  testWidgets('testWhenTheSkillIsAtLevelOneThenItShowsItsLevelTheNextOneAndUpgrade', (tester) async {
    // given
    var upgrades = 0;
    final item = SkillItemDataMock.doubleStrikeAtLevelOneUpgradable;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () => upgrades++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));

    // then
    expect(upgrades, 1);
    expect(find.text(Internationalize.forestHeroSkillLevel(level: 1, max: 3)), findsOneWidget);
    expect(find.text(item.nextText!), findsOneWidget);
    expect(find.text(Internationalize.forestHeroUpgrade), findsOneWidget);
  });

  testWidgets('testWhenTheUpgradeIsUnaffordableThenUpgradeIsDisabledWithTheSameKey', (tester) async {
    // given
    final item = SkillItemDataMock.doubleStrikeAtLevelTwo;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () {}),
        ),
      ),
    );

    // then
    final button = tester.widget<HudButton>(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));
    expect((button.label, button.onPressed), (Internationalize.forestHeroUpgrade, isNull));
    expect(find.text(Internationalize.forestHeroSkillLevel(level: 2, max: 3)), findsOneWidget);
    expect(find.text(item.nextText!), findsOneWidget);
    expect(find.text(item.reasonText!), findsOneWidget);
  });

  testWidgets('testWhenTheSkillIsAtTheMaxLevelThenSaysMaxInsteadOfAButton', (tester) async {
    // given
    final item = SkillItemDataMock.doubleStrikeMaxed;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(width: 340, child: SkillTile(item: item)),
      ),
    );

    // then
    expect(find.byType(HudButton), findsNothing);
    expect(find.text(Internationalize.forestHeroSkillMax), findsOneWidget);
    expect(find.text(Internationalize.forestHeroSkillLevel(level: 3, max: 3)), findsOneWidget);
    expect(item.nextText, isNull);
  });
}
