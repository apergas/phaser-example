import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

extension HudTestApp on WidgetTester {
  Future<void> pumpHud(Widget child) {
    return pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: CustomColors.black,
          body: child,
        ),
      ),
    );
  }
}
