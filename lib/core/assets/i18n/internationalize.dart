import 'package:easy_localization/easy_localization.dart';

class Internationalize {
  static const String _app = 'app';
  static String get appTitle => '$_app.title'.tr();

  static const String _common = 'common';
  static String get commonError => '$_common.error'.tr();
  static String get commonAccept => '$_common.accept'.tr();

  static const String _error = 'error';
  static String get errorGenericTitle => '$_error.genericTitle'.tr();
  static String get errorGenericMessage => '$_error.genericMessage'.tr();
  static String get errorInvalidLevelTitle => '$_error.invalidLevelTitle'.tr();
  static String errorInvalidLevelMessage({required String reason}) =>
      '$_error.invalidLevelMessage'.tr(namedArgs: {'reason': reason});
  static String get errorUnknownTreeKindTitle => '$_error.unknownTreeKindTitle'.tr();
  static String errorUnknownTreeKindMessage({required String detail}) =>
      '$_error.unknownTreeKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownDecorationKindTitle => '$_error.unknownDecorationKindTitle'.tr();
  static String errorUnknownDecorationKindMessage({required String detail}) =>
      '$_error.unknownDecorationKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownItemKindTitle => '$_error.unknownItemKindTitle'.tr();
  static String errorUnknownItemKindMessage({required String detail}) =>
      '$_error.unknownItemKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorNoGameInProgressTitle => '$_error.noGameInProgressTitle'.tr();
  static String get errorNoGameInProgressMessage => '$_error.noGameInProgressMessage'.tr();
}
