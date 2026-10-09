import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/skill_tile.dart';

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

  testWidgets('testWhenTheSkillIsKnownThenSaysSoInsteadOfALearnButton', (tester) async {
    // given
    final item = SkillItemDataMock.doubleStrikeKnown;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(width: 340, child: SkillTile(item: item)),
      ),
    );

    // then
    expect(find.byType(HudButton), findsNothing);
    expect(find.text(Internationalize.forestHeroKnown), findsOneWidget);
  });
}
