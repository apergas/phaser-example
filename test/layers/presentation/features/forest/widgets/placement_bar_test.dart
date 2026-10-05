import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/placement_bar.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenConfirmIsTappedThenOnConfirmIsCalled', (tester) async {
    // given
    var confirms = 0;
    var cancels = 0;
    await tester.pumpHud(PlacementBar(onConfirm: () => confirms++, onCancel: () => cancels++));

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));

    // then
    expect(confirms, 1);
    expect(cancels, 0);
  });

  testWidgets('testWhenCancelIsTappedThenOnCancelIsCalled', (tester) async {
    // given
    var confirms = 0;
    var cancels = 0;
    await tester.pumpHud(PlacementBar(onConfirm: () => confirms++, onCancel: () => cancels++));

    // when
    await tester.tap(find.text(Internationalize.forestPlacementCancel));

    // then
    expect(cancels, 1);
    expect(confirms, 0);
  });
}
