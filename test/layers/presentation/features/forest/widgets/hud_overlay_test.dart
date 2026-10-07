import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_menu.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hero_panel.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_overlay.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hud_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  Future<List<BlueprintId>> pumpOverlay(
    WidgetTester tester,
    HudData hud, {
    List<GearId>? gears,
    VoidCallback? onArenaPressed,
  }) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(
      HudOverlay(
        hud: hud,
        onBuildSelected: selected.add,
        onGearSelected: (gears ?? []).add,
        onArenaPressed: onArenaPressed ?? () {},
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

  testWidgets('testWhenTheScreenIsNarrowThenResourceLabelsAreHidden', (tester) async {
    // given
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.start);

    // then
    expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('testWhenTheScreenIsVeryNarrowThenTheOpenMenuStaysInsideIt', (tester) async {
    // given
    tester.view.physicalSize = const Size(260, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpOverlay(tester, HudDataMock.gathering);

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(tester.getTopRight(find.byType(BuildMenu)).dx, lessThanOrEqualTo(260));
    expect(tester.getTopLeft(find.byType(BuildMenu)).dx, greaterThanOrEqualTo(0));
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

  testWidgets('testWhenTheScreenIsALandscapePhoneThenTheFourButtonsFitOnScreen', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.gathering);

    // then
    final buttons = find.byType(HudButton);
    expect(buttons, findsNWidgets(4));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(buttons.first).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopRight(buttons.last).dx, lessThanOrEqualTo(640));
  });
}
