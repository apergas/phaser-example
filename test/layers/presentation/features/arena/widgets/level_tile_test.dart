import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_tile.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAnOpenLevelIsShownThenNamePowerInItsToneAndRewardAreListed', (tester) async {
    // given
    var taps = 0;
    final level = ArenaLevelItemDataMock.rookieOpen;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: true, isEnabled: true, onTap: () => taps++),
      ),
    );
    await tester.tap(find.text(level.name));

    // then
    expect(find.text(level.enemiesText), findsOneWidget);
    expect(find.text(level.rewardText), findsOneWidget);
    expect(tester.widget<Text>(find.text(level.powerText)).style!.color, CustomColors.success);
    expect(taps, 1);
  });

  testWidgets('testWhenALevelIsLockedThenItShowsTheLockAndCannotBeTapped', (tester) async {
    // given
    var taps = 0;
    final level = ArenaLevelItemDataMock.veteranLocked;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: false, isEnabled: true, onTap: () => taps++),
      ),
    );
    await tester.tap(find.text(level.name));

    // then
    expect(tester.widget<Icon>(find.byIcon(Icons.lock)).semanticLabel, Internationalize.arenaLocked);
    expect(tester.widget<Text>(find.text(level.powerText)).style!.color, CustomColors.error);
    expect(taps, 0);
  });

  testWidgets('testWhenALevelIsClearedThenItSaysSo', (tester) async {
    // given
    final level = ArenaLevelItemDataMock.rookieCleared;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: false, isEnabled: true, onTap: () {}),
      ),
    );

    // then
    expect(find.text(Internationalize.arenaCleared), findsOneWidget);
  });
}
