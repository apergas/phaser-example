import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_option_tile.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/build_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenItemIsAffordableThenTappingCallsOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 300,
          child: BuildOptionTile(item: BuildItemDataMock.affordable, onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text(BuildItemDataMock.affordable.name));

    // then
    expect(taps, 1);
    expect(find.text(BuildItemDataMock.affordable.costText), findsOneWidget);
    expect(find.text(BuildItemDataMock.unaffordable.missingText!), findsNothing);
  });

  testWidgets('testWhenItemIsNotAffordableThenItShowsTheMissingTextMuted', (tester) async {
    // given
    final tile = BuildOptionTile(item: BuildItemDataMock.unaffordable);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 300, child: tile)));

    // then
    expect(find.text(BuildItemDataMock.unaffordable.missingText!), findsOneWidget);
    expect(tester.widget<Text>(find.text(BuildItemDataMock.affordable.name)).style!.color, CustomColors.hudMuted);
    expect(tester.widget<Text>(find.text(BuildItemDataMock.affordable.costText)).style!.color, CustomColors.hudMuted);
  });
}
