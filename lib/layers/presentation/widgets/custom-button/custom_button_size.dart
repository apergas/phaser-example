import 'package:flutter/material.dart';

import '../../theme/styles/custom_text_styles.dart';

enum CustomButtonSize {
  small,
  standard;

  double get size {
    switch (this) {
      case CustomButtonSize.small:
        return 40;
      case CustomButtonSize.standard:
        return 48;
    }
  }

  TextStyle get textStyle {
    switch (this) {
      case CustomButtonSize.small:
        return CustomTextStyles.system12w700;
      case CustomButtonSize.standard:
        return CustomTextStyles.system14w700;
    }
  }

  double get spacing {
    switch (this) {
      case CustomButtonSize.small:
        return 4;
      case CustomButtonSize.standard:
        return 8;
    }
  }

  double get iconSize {
    switch (this) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.standard:
        return 18;
    }
  }
}
