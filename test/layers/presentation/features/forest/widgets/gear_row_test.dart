import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_row.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/gear_row_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenThereIsANextPieceThenShowsTheEquippedOneAndReportsTheNextOnBuy', (tester) async {
    // given
    final bought = <GearId>[];
    final row = GearRowDataMock.weaponReadyToBuy;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearRow(row: row, onBuy: bought.add),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(bought, [GearId.shortSword]);
    expect(find.text(row.title.toUpperCase()), findsOneWidget);
    expect(find.text(row.equipped.name), findsOneWidget);
    expect(find.text(Internationalize.forestHeroEquipped), findsOneWidget);
  });

  testWidgets('testWhenTheBestPieceIsEquippedThenSaysSoInsteadOfATile', (tester) async {
    // given
    final row = GearRowDataMock.weaponMaxed;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearRow(row: row, onBuy: (_) {}),
        ),
      ),
    );

    // then
    expect(find.byType(GearOptionTile), findsNothing);
    expect(find.text(Internationalize.forestHeroMaxed), findsOneWidget);
  });
}
