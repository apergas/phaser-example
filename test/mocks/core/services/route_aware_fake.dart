import 'package:flutter/widgets.dart';

class RouteAwareFake with RouteAware {
  final List<String> calls = [];

  @override
  void didPushNext() => calls.add('didPushNext');

  @override
  void didPopNext() => calls.add('didPopNext');
}
