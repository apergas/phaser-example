import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:farming/layers/presentation/features/forest/widgets/upgrade_option_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/upgrade_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheUpgradeCanBeBoughtThenTappingBuyCallsOnBuy', (tester) async {
    // given
    var buys = 0;
    final item = UpgradeItemDataMock.axeOption;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: UpgradeOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironAxe)));

    // then
    expect(buys, 1);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.effectText), findsOneWidget);
    expect(find.text(item.costText), findsOneWidget);
  });

  testWidgets('testWhenTheUpgradeCannotBeBoughtThenBuyIsDisabledAndTheReasonIsShown', (tester) async {
    // given
    var buys = 0;
    final item = UpgradeItemDataMock.withoutWorkshop.last;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: UpgradeOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );
    await tester.tap(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironPickaxe)));

    // then
    expect(buys, 0);
    expect(tester.widget<HudButton>(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironPickaxe))).onPressed, isNull);
    expect(find.text(item.reasonText!), findsOneWidget);
  });

  testWidgets('testWhenTheUpgradeIsOwnedThenTheCostSaysSoWithoutAReason', (tester) async {
    // given
    final item = UpgradeItemDataMock.axeOwnedAndPickaxeShort.first;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: UpgradeOptionTile(item: item, onBuy: () {}),
        ),
      ),
    );

    // then
    expect(find.text(item.costText), findsOneWidget);
    expect(item.reasonText, isNull);
    expect(tester.widget<HudButton>(find.byKey(UpgradeOptionTile.buyKey(UpgradeId.ironAxe))).onPressed, isNull);
  });
}
