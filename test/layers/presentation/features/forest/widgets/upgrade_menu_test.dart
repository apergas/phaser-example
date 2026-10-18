import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/presentation/features/forest/widgets/upgrade_menu.dart';
import 'package:farming/layers/presentation/features/forest/widgets/upgrade_option_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/upgrade_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenShownThenItHasTheTitleAndOneRowPerUpgrade', (tester) async {
    // given
    final items = UpgradeItemDataMock.axeAffordable;

    // when
    await tester.pumpHud(
      Center(
        child: UpgradeMenu(items: items, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.text(Internationalize.forestUpgradeTitle.toUpperCase()), findsOneWidget);
    expect(find.byType(UpgradeOptionTile), findsNWidgets(items.length));
  });

  testWidgets('testWhenBuyingAnUpgradeThenItsIdIsReported', (tester) async {
    // given
    final bought = <UpgradeId>[];
    await tester.pumpHud(
      Center(
        child: UpgradeMenu(items: UpgradeItemDataMock.axeAffordable, onBuy: bought.add),
      ),
    );

    // when
    await tester.tap(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironAxe)));

    // then
    expect(bought, [UpgradeId.ironAxe]);
  });
}
