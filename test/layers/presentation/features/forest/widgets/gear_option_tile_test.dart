import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/gear_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheGearCanBeBoughtThenTappingBuyCallsOnBuy', (tester) async {
    // given
    var buys = 0;
    final item = GearItemDataMock.shortSwordAvailable;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(buys, 1);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.statsText), findsOneWidget);
    expect(find.text(item.costText!), findsOneWidget);
  });

  testWidgets('testWhenTheWorkshopIsMissingThenBuyIsDisabledAndTheReasonIsShown', (tester) async {
    // given
    var buys = 0;
    final item = GearItemDataMock.shortSwordNeedsForge;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(buys, 0);
    expect(tester.widget<HudButton>(find.byKey(GearOptionTile.buyKey(GearId.shortSword))).onPressed, isNull);
    expect(find.text(item.reasonText!), findsOneWidget);
  });
}
