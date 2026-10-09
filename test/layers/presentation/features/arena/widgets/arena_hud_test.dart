import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_result_data.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/arena_hud.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/fight_button.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  Future<List<String>> pumpHud(WidgetTester tester, {required bool isReplaying, ArenaResultData? result}) async {
    final calls = <String>[];
    await tester.pumpHud(
      ArenaHud(
        levels: [ArenaLevelItemDataMock.rookieOpen, ArenaLevelItemDataMock.veteranLocked],
        selected: ArenaLevelId.banditRookie,
        heroPower: 31,
        isReplaying: isReplaying,
        canFight: !isReplaying,
        result: result,
        onLevelSelected: (id) => calls.add(id.name),
        onFight: () => calls.add('fight'),
        onSkip: () => calls.add('skip'),
        onBack: () => calls.add('back'),
      ),
    );
    return calls;
  }

  testWidgets('testWhenShownThenTheHeroPowerTheLevelsAndTheFightButtonAreThere', (tester) async {
    // given
    final calls = await pumpHud(tester, isReplaying: false);

    // when
    await tester.tap(find.text(Internationalize.arenaFight));
    await tester.tap(find.text(Internationalize.arenaBack));

    // then
    expect(find.text(Internationalize.arenaHeroPower(power: 31)), findsOneWidget);
    expect(find.text(ArenaLevelItemDataMock.rookieOpen.name), findsOneWidget);
    expect(calls, ['fight', 'back']);
  });

  testWidgets('testWhenTheFightEndedThenTheResultIsShown', (tester) async {
    // given
    // when
    await pumpHud(tester, isReplaying: false, result: ArenaResultDataMock.victoryTenGold);

    // then
    expect(find.byType(ResultPanel), findsOneWidget);
  });

  testWidgets('testWhenReplayingThenTheResultIsHiddenAndTheLevelsIgnoreTaps', (tester) async {
    // given
    final calls = await pumpHud(tester, isReplaying: true, result: ArenaResultDataMock.victoryTenGold);

    // when
    await tester.tap(find.text(ArenaLevelItemDataMock.rookieOpen.name));
    await tester.tap(find.text(Internationalize.arenaSkip));

    // then
    expect(find.byType(ResultPanel), findsNothing);
    expect(calls, ['skip']);
  });

  for (final size in const [Size(915, 412), Size(844, 390), Size(640, 360)]) {
    testWidgets('testWhenTheScreenIsALowLandscapePhoneThenTheResultStaysRightOfTheFighters ${size.width}', (
      tester,
    ) async {
      // given
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // when
      await pumpHud(tester, isReplaying: false, result: ArenaResultDataMock.defeatNeedAttack);

      // then
      final panel = tester.getRect(find.byType(ResultPanel));
      expect(tester.takeException(), isNull);
      expect(panel.left, greaterThan(size.width * 0.78));
      expect(panel.bottom, lessThan(tester.getRect(find.byType(FightButton)).top));
      expect(find.text(Internationalize.arenaRetry), findsOneWidget);
    });
  }

  testWidgets('testWhenTheScreenIsTallThenTheResultIsTheFullPanel', (tester) async {
    // given
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpHud(tester, isReplaying: false, result: ArenaResultDataMock.defeatNeedAttack);

    // then
    expect(tester.getSize(find.byType(ResultPanel)).width, ResultPanel.maxWidth);
  });
}
