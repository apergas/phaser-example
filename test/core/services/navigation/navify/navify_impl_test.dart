import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';

void main() {
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
    navify.showSnackbar(message: '+6 de madera');
    await tester.pump();

    // then
    expect(find.text('+6 de madera'), findsOneWidget);
  });

  testWidgets('testWhenShowingASecondSnackbarThenOnlyTheLastOneIsVisible', (tester) async {
    // given
    await pumpApp(tester);
    navify.showSnackbar(message: 'Manos a la obra…');
    await tester.pump();

    // when
    navify.showSnackbar(message: '¡Casa construida!');
    await tester.pumpAndSettle();

    // then
    expect(find.text('Manos a la obra…'), findsNothing);
    expect(find.text('¡Casa construida!'), findsOneWidget);
  });

  testWidgets('testWhenPushingAPageThenItCanBePopped', (tester) async {
    // given
    await pumpApp(tester);

    // when
    navify.push(const Scaffold(body: Text('second')));
    await tester.pumpAndSettle();

    // then
    expect(find.text('second'), findsOneWidget);
    expect(navify.canPop(), isTrue);
  });
}
