import 'dart:ui';

import '../../theme/colors/custom_colors.dart';

enum CustomButtonColor {
  dark,
  white,
  light,
  lightTwo,
  success,
  failure,
  warning;

  Color get background {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.black;
      case CustomButtonColor.white:
        return CustomColors.white;
      case CustomButtonColor.light:
        return CustomColors.gray1Background;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }

  Color get foreground {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.white;
      case CustomButtonColor.white:
        return CustomColors.black;
      case CustomButtonColor.light:
        return CustomColors.black;
      case CustomButtonColor.lightTwo:
        return CustomColors.black;
      case CustomButtonColor.success:
        return CustomColors.white;
      case CustomButtonColor.failure:
        return CustomColors.white;
      case CustomButtonColor.warning:
        return CustomColors.white;
    }
  }

  Color get backgroundDisable {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.gray4;
      case CustomButtonColor.white:
        return CustomColors.white;
      case CustomButtonColor.light:
        return CustomColors.gray1Background;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }

  Color get foregroundDisable {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.black.withValues(alpha: 0.38);
      case CustomButtonColor.white:
        return CustomColors.black.withValues(alpha: 0.20);
      case CustomButtonColor.light:
        return CustomColors.gray4;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }
}
