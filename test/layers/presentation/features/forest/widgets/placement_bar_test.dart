import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/layers/presentation/features/forest/widgets/placement_bar.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  String blocked() => Internationalize.forestPlacementRejection(rejection: ConstructionRejection.blocked);

  testWidgets('testWhenConfirmIsTappedThenOnConfirmIsCalled', (tester) async {
    // given
    var confirms = 0;
    var cancels = 0;
    await tester.pumpHud(PlacementBar(reason: null, onConfirm: () => confirms++, onCancel: () => cancels++));

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
    await tester.pumpHud(PlacementBar(reason: null, onConfirm: () => confirms++, onCancel: () => cancels++));

    // when
    await tester.tap(find.text(Internationalize.forestPlacementCancel));

    // then
    expect(cancels, 1);
    expect(confirms, 0);
  });

  testWidgets('testWhenThereIsAReasonThenItIsShownAndRead', (tester) async {
    // given
    final reason = blocked();

    // when
    await tester.pumpHud(PlacementBar(reason: reason, onConfirm: () {}, onCancel: () {}));

    // then
    expect(find.text(reason), findsOneWidget);
    expect(find.bySemanticsLabel(reason), findsOneWidget);
    expect(tester.widget<Opacity>(find.ancestor(of: find.text(reason), matching: find.byType(Opacity))).opacity, 1);
  });

  testWidgets('testWhenThereIsNoReasonThenTheLabelIsHiddenAndNotRead', (tester) async {
    // given
    // when
    await tester.pumpHud(PlacementBar(reason: null, onConfirm: () {}, onCancel: () {}));

    // then
    expect(find.text(blocked()), findsNothing);
    final label = find.ancestor(of: find.text(' '), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(label.first).opacity, 0);
    expect(
      tester
          .widget<ExcludeSemantics>(find.ancestor(of: label.first, matching: find.byType(ExcludeSemantics)).first)
          .excluding,
      isTrue,
    );
  });

  testWidgets('testWhenTheReasonComesAndGoesThenTheBarKeepsItsHeight', (tester) async {
    // given
    await tester.pumpHud(PlacementBar(reason: null, onConfirm: () {}, onCancel: () {}));
    final without = tester.getSize(find.byType(PlacementBar)).height;

    // when
    await tester.pumpHud(PlacementBar(reason: blocked(), onConfirm: () {}, onCancel: () {}));

    // then
    expect(tester.getSize(find.byType(PlacementBar)).height, without);
  });
}
