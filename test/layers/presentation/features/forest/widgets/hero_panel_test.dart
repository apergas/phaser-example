import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_row.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hero_panel.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/skill_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenShownThenListsPowerTheThreeStatsAndOneRowPerSlot', (tester) async {
    // given
    final hero = HeroPanelDataMock.newHero;

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.text(Internationalize.forestHeroPower), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text(Internationalize.forestHeroAttack), findsOneWidget);
    expect(find.text(Internationalize.forestHeroDefense), findsOneWidget);
    expect(find.text(Internationalize.forestHeroHealth), findsOneWidget);
    expect(find.byType(GearRow), findsNWidgets(2));
    expect(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.gear)), findsNothing);
  });

  testWidgets('testWhenBuyIsTappedThenReportsThePiece', (tester) async {
    // given
    final bought = <GearId>[];
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: HeroPanelDataMock.readyToBuySword, onBuy: bought.add),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(bought, [GearId.shortSword]);
  });

  testWidgets('testWhenTheSkillsTabIsTappedThenListsOneTilePerSkillInsteadOfTheGear', (tester) async {
    // given
    final hero = HeroPanelDataMock.readyToLearnDoubleStrike;
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}, onLearn: (_) {}, sections: HeroPanelSection.values),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(find.byType(SkillTile), findsNWidgets(hero.skills.length));
    expect(find.byType(GearRow), findsNothing);
    expect(find.text(hero.skills.first.description), findsOneWidget);
  });

  testWidgets('testWhenLearnIsTappedThenReportsTheSkill', (tester) async {
    // given
    final learned = <SkillId>[];
    await tester.pumpHud(
      Center(
        child: HeroPanel(
          hero: HeroPanelDataMock.readyToLearnDoubleStrike,
          onBuy: (_) {},
          onLearn: learned.add,
          sections: HeroPanelSection.values,
        ),
      ),
    );
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // when
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));

    // then
    expect(learned, [SkillId.doubleStrike]);
  });

  testWidgets('testWhenTheOpenSectionIsNoLongerOfferedThenThePanelGoesBackToTheFirstOne', (tester) async {
    // given
    final hero = HeroPanelDataMock.newHero;
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}, sections: HeroPanelSection.values),
      ),
    );
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.byType(GearRow), findsNWidgets(2));
    expect(find.byType(SkillTile), findsNothing);
  });

  test('testWhenThereAreNoSectionsThenThePanelCannotBeCreated', () {
    // given
    final hero = HeroPanelDataMock.newHero;

    // when
    HeroPanel create() => HeroPanel(hero: hero, onBuy: (_) {}, sections: const []);

    // then
    expect(create, throwsAssertionError);
  });

  testWidgets('testWhenTheScreenIsAShortLandscapePhoneThenThePanelScrollsWithoutOverflowing', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await tester.pumpHud(
      Align(
        alignment: Alignment.topRight,
        child: HeroPanel(hero: HeroPanelDataMock.newHero, onBuy: (_) {}),
      ),
    );

    // then
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HeroPanel)).height, lessThanOrEqualTo(360 - HeroPanel.reservedHeight));
  });

  testWidgets('testWhenTheSkillsTabIsOpenOnAShortLandscapePhoneThenItScrollsWithoutOverflowing', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpHud(
      Align(
        alignment: Alignment.topRight,
        child: HeroPanel(
          hero: HeroPanelDataMock.readyToLearnDoubleStrike,
          onBuy: (_) {},
          onLearn: (_) {},
          sections: HeroPanelSection.values,
        ),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HeroPanel)).height, lessThanOrEqualTo(360 - HeroPanel.reservedHeight));
  });
}
