import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_menu.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/build_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAnEnabledItemIsTappedThenOnSelectedReceivesItsBlueprint', (tester) async {
    // given
    final selected = <BlueprintId>[];
    await tester.pumpHud(
      Center(
        child: BuildMenu(items: [BuildItemDataMock.affordable], onSelected: selected.add),
      ),
    );

    // when
    await tester.tap(find.text('Casa'));

    // then
    expect(selected, [BlueprintId.house]);
  });

  testWidgets('testWhenADisabledItemIsTappedThenOnSelectedIsNotCalled', (tester) async {
    // given
    final selected = <BlueprintId>[];
    await tester.pumpHud(
      Center(
        child: BuildMenu(items: [BuildItemDataMock.unaffordable], onSelected: selected.add),
      ),
    );

    // when
    await tester.tap(find.text('Casa'));

    // then
    expect(selected, isEmpty);
  });
}
