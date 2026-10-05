import 'package:flutter/material.dart';

import 'colors/custom_colors.dart';
import 'styles/custom_text_styles.dart';

class CustomTheme {
  CustomTheme._();

  static final data = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.hudAccent, brightness: .dark),
    scaffoldBackgroundColor: CustomColors.black,
    textTheme: _textTheme(),
    snackBarTheme: _snackBarTheme(),
    dialogTheme: _dialogTheme(),
    progressIndicatorTheme: _progressIndicatorTheme(),
  );

  static TextTheme _textTheme() {
    return TextTheme(
      headlineSmall: CustomTextStyles.system24w400,
      titleMedium: CustomTextStyles.system18w600,
      labelLarge: CustomTextStyles.system14w700,
      bodyLarge: CustomTextStyles.system16w400,
      bodyMedium: CustomTextStyles.system14w400,
    );
  }

  static SnackBarThemeData _snackBarTheme() {
    return SnackBarThemeData(
      contentTextStyle: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
      behavior: SnackBarBehavior.floating,
    );
  }

  static DialogThemeData _dialogTheme() {
    return DialogThemeData(
      backgroundColor: CustomColors.hudBackground,
      shape: RoundedRectangleBorder(borderRadius: .circular(8)),
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme() {
    return const ProgressIndicatorThemeData(color: CustomColors.hudAccent);
  }
}
