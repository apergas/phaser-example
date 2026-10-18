import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:farming/core/config/constants/enum/gear_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/presentation/features/forest/models/hud_data.dart';
import 'package:farming/layers/presentation/features/forest/widgets/build_menu.dart';
import 'package:farming/layers/presentation/features/forest/widgets/build_option_tile.dart';
import 'package:farming/layers/presentation/features/forest/widgets/game_panel.dart';
import 'package:farming/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hero_panel.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hud_overlay.dart';
import 'package:farming/layers/presentation/features/forest/widgets/quest_panel.dart';
import 'package:farming/layers/presentation/features/forest/widgets/quest_row.dart';
import 'package:farming/layers/presentation/features/forest/widgets/resource_bar.dart';
import 'package:farming/layers/presentation/features/forest/widgets/skill_tile.dart';
import 'package:farming/layers/presentation/features/forest/widgets/upgrade_menu.dart';
import 'package:farming/layers/presentation/features/forest/widgets/upgrade_option_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/roboto_font.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hud_data_mock.dart';

void main() {
  setUpAll(() async {
    loadSpanishTranslations();
    await loadRobotoFont();
  });

  Future<List<BlueprintId>> pumpOverlay(
    WidgetTester tester,
    HudData hud, {
    List<GearId>? gears,
    VoidCallback? onArenaPressed,
    List<SkillId>? skills,
    List<UpgradeId>? upgrades,
    VoidCallback? onSaveRequested,
    VoidCallback? onNewGameRequested,
  }) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(
      HudOverlay(
        hud: hud,
        onBuildSelected: selected.add,
        onGearSelected: (gears ?? []).add,
        onArenaPressed: onArenaPressed ?? () {},
        onSkillSelected: (skills ?? []).add,
        onUpgradeSelected: (upgrades ?? []).add,
        onSaveRequested: onSaveRequested ?? () {},
        onNewGameRequested: onNewGameRequested ?? () {},
      ),
    );
    return selected;
  }

  HudButton buildButton(WidgetTester tester) {
    return tester.widget<HudButton>(
      find.ancestor(of: find.text(Internationalize.forestBuild), matching: find.byType(HudButton)),
    );
  }

  testWidgets('testWhenRenderedThenItShowsResourcesAndTheQuestBadge', (tester) async {
    // given
    final hud = HudDataMock.gathering;

    // when
    await pumpOverlay(tester, hud);

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(QuestPanel), findsNothing);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenQuestsButtonIsTappedThenTheQuestPanelOpens', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);

    // when
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // then
    expect(find.byType(QuestPanel), findsOneWidget);
  });

  testWidgets('testWhenQuestsButtonIsTappedTwiceThenTheQuestPanelCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // then
    expect(find.byType(QuestPanel), findsNothing);
  });

  testWidgets('testWhenBuildIsTappedWhileQuestsAreOpenThenOnlyTheBuildMenuIsShown', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(find.byType(BuildMenu), findsOneWidget);
    expect(find.byType(QuestPanel), findsNothing);
  });

  testWidgets('testWhenABuildOptionIsSelectedThenTheMenuClosesAndTheBlueprintIsReported', (tester) async {
    // given
    final selected = await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestBlueprint(id: BlueprintId.house)));
    await tester.pump();

    // then
    expect(selected, [BlueprintId.house]);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenBuildIsLockedThenTheBuildButtonIsDisabled', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.placing);

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(buildButton(tester).onPressed, isNull);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenBuildBecomesLockedWhileTheMenuIsOpenThenTheMenuCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // when
    await pumpOverlay(tester, HudDataMock.placing);

    // then
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenTheScreenIsJustBelowTheNarrowWidthThenResourceLabelsAreHidden', (tester) async {
    // given
    tester.view.physicalSize = const Size(HudOverlay.narrowWidth - 1, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.start);

    // then
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsNothing);
    expect(find.text(Internationalize.forestStock), findsNothing);
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('testWhenTheScreenIsAtTheNarrowWidthThenTheLabelledBarFitsWithEveryAmountAtFourDigits', (tester) async {
    // given
    tester.view.physicalSize = const Size(HudOverlay.narrowWidth, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    expect(tester.takeException(), isNull);
    expect(find.text(Internationalize.forestStock), findsOneWidget);
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsOneWidget);
    expect(tester.getRect(find.byType(ResourceBar)).right, lessThanOrEqualTo(HudOverlay.narrowWidth - 12));
  });

  testWidgets('testWhenTheScreenIsALowLandscapePhoneThenTheOpenMenuStaysInsideIt', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpOverlay(tester, HudDataMock.gathering);

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(tester.takeException(), isNull);
    expect(tester.getTopRight(find.byType(BuildMenu)).dx, lessThanOrEqualTo(640));
    expect(tester.getTopLeft(find.byType(BuildMenu)).dx, greaterThanOrEqualTo(0));
  });

  testWidgets('testWhenTheWorkshopIsTappedThenItsMenuOpensAndBuyingReportsTheUpgradeWithoutClosingIt', (tester) async {
    // given
    final upgrades = <UpgradeId>[];
    await pumpOverlay(tester, HudDataMock.withUpgradeReady, upgrades: upgrades);

    // when
    await tester.tap(find.text(Internationalize.forestWorkshop));
    await tester.pump();
    await tester.tap(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironAxe)));
    await tester.pump();

    // then
    expect(upgrades, [UpgradeId.ironAxe]);
    expect(find.byType(UpgradeMenu), findsOneWidget);
  });

  testWidgets('testWhenTheWorkshopIsTappedTwiceThenItsMenuCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.withUpgradeReady);
    await tester.tap(find.text(Internationalize.forestWorkshop));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestWorkshop));
    await tester.pump();

    // then
    expect(find.byType(UpgradeMenu), findsNothing);
  });

  testWidgets('testWhenArenaIsTappedWhileTheWorkshopIsOpenThenTheWorkshopCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.withUpgradeReady);
    await tester.tap(find.text(Internationalize.forestWorkshop));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestArena));
    await tester.pump();

    // then
    expect(find.byType(UpgradeMenu), findsNothing);
  });

  testWidgets('testWhenTheGameButtonIsTappedThenThePanelOpensAndTappingAgainClosesIt', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);

    // when
    await tester.tap(find.text(Internationalize.forestGame));
    await tester.pump();
    final opened = find.byType(GamePanel).evaluate().length;
    await tester.tap(find.text(Internationalize.forestGame).first);
    await tester.pump();

    // then
    expect(opened, 1);
    expect(find.byType(GamePanel), findsNothing);
  });

  testWidgets('testWhenSaveIsTappedThenTheSaveIsRequestedAndThePanelCloses', (tester) async {
    // given
    var saves = 0;
    await pumpOverlay(tester, HudDataMock.gathering, onSaveRequested: () => saves++);
    await tester.tap(find.text(Internationalize.forestGame));
    await tester.pump();

    // when
    await tester.tap(find.byKey(GamePanel.saveKey));
    await tester.pump();

    // then
    expect(saves, 1);
    expect(find.byType(GamePanel), findsNothing);
  });

  testWidgets('testWhenANewGameIsConfirmedThenItIsRequestedAndThePanelCloses', (tester) async {
    // given
    var newGames = 0;
    await pumpOverlay(tester, HudDataMock.gathering, onNewGameRequested: () => newGames++);
    await tester.tap(find.text(Internationalize.forestGame));
    await tester.pump();
    await tester.tap(find.byKey(GamePanel.newGameKey));
    await tester.pump();

    // when
    await tester.tap(find.byKey(GamePanel.confirmKey));
    await tester.pump();

    // then
    expect(newGames, 1);
    expect(find.byType(GamePanel), findsNothing);
  });

  testWidgets('testWhenArenaIsTappedWhileTheGamePanelIsOpenThenThePanelCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestGame));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestArena));
    await tester.pump();

    // then
    expect(find.byType(GamePanel), findsNothing);
  });

  testWidgets('testWhenRenderedThenTheSixButtonsComeInOrder', (tester) async {
    // given
    tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.gathering);

    // then
    final labels = tester.widgetList<HudButton>(find.byType(HudButton)).map((button) => button.label).toList();
    expect(labels, [
      Internationalize.forestQuests,
      Internationalize.forestBuild,
      Internationalize.forestWorkshop,
      Internationalize.forestHero,
      Internationalize.forestArena,
      Internationalize.forestGame,
    ]);
  });

  testWidgets('testWhenHeroIsTappedThenTheHeroPanelOpensAndBuyingReportsThePiece', (tester) async {
    // given
    final gears = <GearId>[];
    await pumpOverlay(tester, HudDataMock.withHeroReadyToBuy, gears: gears);

    // when
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));
    await tester.pump();

    // then
    expect(find.byType(HeroPanel), findsOneWidget);
    expect(gears, [GearId.shortSword]);
  });

  testWidgets('testWhenTheSkillsTabIsOpenedThenLearningReportsTheSkill', (tester) async {
    // given
    final skills = <SkillId>[];
    await pumpOverlay(tester, HudDataMock.withSkillReadyToLearn, skills: skills);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));
    await tester.pump();

    // then
    expect(find.byType(SkillTile), findsNWidgets(3));
    expect(skills, [SkillId.doubleStrike]);
  });

  testWidgets('testWhenBuildIsTappedWhileTheHeroPanelIsOpenThenOnlyTheBuildMenuIsShown', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(find.byType(BuildMenu), findsOneWidget);
    expect(find.byType(HeroPanel), findsNothing);
  });

  testWidgets('testWhenArenaIsTappedThenTheOpenMenuClosesAndTheArenaIsRequested', (tester) async {
    // given
    var arenaTaps = 0;
    await pumpOverlay(tester, HudDataMock.gathering, onArenaPressed: () => arenaTaps++);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestArena));
    await tester.pump();

    // then
    expect(arenaTaps, 1);
    expect(find.byType(QuestPanel), findsNothing);
  });

  testWidgets('testWhenArenaIsTappedWhileTheHeroPanelIsOpenThenTheHeroPanelCloses', (tester) async {
    // given
    var arenaTaps = 0;
    await pumpOverlay(tester, HudDataMock.gathering, onArenaPressed: () => arenaTaps++);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestArena));
    await tester.pump();

    // then
    expect(arenaTaps, 1);
    expect(find.byType(HeroPanel), findsNothing);
  });

  testWidgets('testWhenTheScreenIsALandscapePhoneThenTheSixButtonsGoUnderTheResourceBar', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    final buttons = find.byType(HudButton);
    final resourceBar = tester.getRect(find.byType(ResourceBar));
    expect(buttons, findsNWidgets(6));
    expect(tester.takeException(), isNull);
    for (final button in tester.widgetList<HudButton>(buttons)) {
      final rect = tester.getRect(find.byWidget(button));
      expect(rect.overlaps(resourceBar), isFalse);
      expect(rect.top, greaterThanOrEqualTo(resourceBar.bottom));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(640));
      expect(rect.bottom, lessThanOrEqualTo(360));
    }
    final firstButton = tester.getRect(find.widgetWithText(HudButton, Internationalize.forestQuests));
    expect(firstButton.left, resourceBar.left);
  });

  testWidgets('testWhenTheScreenIsWideThenTheSixButtonsStayOnTheResourceBarLine', (tester) async {
    // given
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    final buttons = find.byType(HudButton);
    final resourceBar = tester.getRect(find.byType(ResourceBar));
    expect(buttons, findsNWidgets(6));
    expect(tester.takeException(), isNull);
    for (final button in tester.widgetList<HudButton>(buttons)) {
      final rect = tester.getRect(find.byWidget(button));
      expect(rect.overlaps(resourceBar), isFalse);
      expect(rect.top, lessThan(resourceBar.bottom));
      expect(rect.right, lessThanOrEqualTo(1920));
    }
  });

  testWidgets('testWhenTheHeroPanelIsOpenOnALandscapePhoneThenItStaysOnScreenUnderTheButtons', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // when
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // then
    final panel = tester.getRect(find.byType(HeroPanel));
    final heroButton = tester.getRect(find.widgetWithText(HudButton, Internationalize.forestHero));
    expect(tester.takeException(), isNull);
    expect(panel.top, greaterThanOrEqualTo(heroButton.bottom));
    expect(panel.left, tester.getRect(find.byType(ResourceBar)).left);
    expect(panel.right, lessThanOrEqualTo(640));
    expect(panel.bottom, lessThanOrEqualTo(360));
  });

  testWidgets('testWhenEveryResourceShowsFourDigitsThenTheBreakpointLeavesRoomForTheButtonsBesideTheBar', (
    tester,
  ) async {
    // given
    const margin = 12.0;
    const gap = 8.0;
    const slack = 24.0;
    tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    final bar = tester.getSize(find.byType(ResourceBar)).width;
    final buttons = tester
        .getSize(
          find
              .ancestor(of: find.widgetWithText(HudButton, Internationalize.forestQuests), matching: find.byType(Row))
              .first,
        )
        .width;
    expect(margin + bar + gap + buttons + margin + slack, lessThanOrEqualTo(HudOverlay.buttonsBelowWidth));
  });

  testWidgets('testWhenTheScreenIsJustBelowTheBreakpointThenTheButtonsGoUnderTheResourceBar', (tester) async {
    // given
    tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth - 1, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    final resourceBar = tester.getRect(find.byType(ResourceBar));
    for (final button in tester.widgetList<HudButton>(find.byType(HudButton))) {
      expect(tester.getRect(find.byWidget(button)).top, greaterThanOrEqualTo(resourceBar.bottom));
    }
  });

  testWidgets('testWhenTheScreenIsAtTheBreakpointThenTheButtonsStayOnTheResourceBarLine', (tester) async {
    // given
    tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

    // then
    final resourceBar = tester.getRect(find.byType(ResourceBar));
    for (final button in tester.widgetList<HudButton>(find.byType(HudButton))) {
      expect(tester.getRect(find.byWidget(button)).top, lessThan(resourceBar.bottom));
    }
  });

  for (final size in const [Size(640, 360), Size(640, 300)]) {
    testWidgets('testWhenTheBuildMenuIsOpenOnALandscapePhoneThenItScrollsOnScreen ${size.width}x${size.height}', (
      tester,
    ) async {
      // given
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

      // when
      await tester.tap(find.text(Internationalize.forestBuild));
      await tester.pump();

      // then
      final menu = tester.getRect(find.byType(BuildMenu));
      expect(tester.takeException(), isNull);
      expect(find.byType(BuildOptionTile, skipOffstage: false), findsNWidgets(BlueprintId.values.length));
      expect(find.descendant(of: find.byType(BuildMenu), matching: find.byType(Scrollable)), findsOneWidget);
      expect(
        menu.top,
        greaterThanOrEqualTo(tester.getRect(find.widgetWithText(HudButton, Internationalize.forestBuild)).bottom),
      );
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.right, lessThanOrEqualTo(size.width));
      expect(menu.bottom, lessThanOrEqualTo(size.height));
    });

    testWidgets('testWhenTheQuestPanelIsOpenOnALandscapePhoneThenItScrollsOnScreen ${size.width}x${size.height}', (
      tester,
    ) async {
      // given
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);

      // when
      await tester.tap(find.text(Internationalize.forestQuests));
      await tester.pump();

      // then
      final panel = tester.getRect(find.byType(QuestPanel));
      expect(tester.takeException(), isNull);
      expect(
        find.byType(QuestRow, skipOffstage: false),
        findsNWidgets(HudDataMock.withEveryResourceAndTool.quests.length),
      );
      expect(
        panel.top,
        greaterThanOrEqualTo(tester.getRect(find.widgetWithText(HudButton, Internationalize.forestQuests)).bottom),
      );
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(size.width));
      expect(panel.bottom, lessThanOrEqualTo(size.height));
    });
  }
}
