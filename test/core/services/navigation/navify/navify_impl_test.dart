import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';

import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/services/route_aware_fake.dart';
import '../../../../mocks/presentation/widgets/widget_text_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  late NavifyImpl navify;

  setUp(() {
    navify = NavifyImpl();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(navigatorKey: navify.navigatorKey, home: const Scaffold()));
  }

  testWidgets('testWhenShowingASnackbarThenItsMessageIsVisible', (tester) async {
    // given
    await pumpApp(tester);

    // when
    navify.showSnackbar(message: Internationalize.forestMessageWoodGained(wood: 6));
    await tester.pump();

    // then
    expect(find.text(Internationalize.forestMessageWoodGained(wood: 6)), findsOneWidget);
  });

  testWidgets('testWhenShowingASecondSnackbarThenOnlyTheLastOneIsVisible', (tester) async {
    // given
    await pumpApp(tester);
    final completed = Internationalize.forestMessageBuildingCompleted(
      name: Internationalize.forestBlueprint(id: BlueprintId.house),
    );
    navify.showSnackbar(message: Internationalize.forestMessageBuildingStarted);
    await tester.pump();

    // when
    navify.showSnackbar(message: completed);
    await tester.pumpAndSettle();

    // then
    expect(find.text(Internationalize.forestMessageBuildingStarted), findsNothing);
    expect(find.text(completed), findsOneWidget);
  });

  testWidgets('testWhenPushingAPageThenItCanBePopped', (tester) async {
    // given
    await pumpApp(tester);

    // when
    navify.push(const Scaffold(body: Text(WidgetTextMock.page)));
    await tester.pumpAndSettle();

    // then
    expect(find.text(WidgetTextMock.page), findsOneWidget);
    expect(navify.canPop(), isTrue);
  });

  testWidgets('testWhenAPageIsPushedOverAnotherThenTheRouteObserverTellsTheOneBelow', (tester) async {
    // given
    final below = RouteAwareFake();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navify.navigatorKey,
        navigatorObservers: [navify.routeObserver],
        home: const Scaffold(),
      ),
    );
    navify.routeObserver.subscribe(below, ModalRoute.of(tester.element(find.byType(Scaffold)))!);

    // when
    navify.push(const Scaffold());
    await tester.pumpAndSettle();
    navify.pop();
    await tester.pumpAndSettle();

    // then
    expect(below.calls, ['didPushNext', 'didPopNext']);
  });
}
