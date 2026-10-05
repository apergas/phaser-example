import '../../assets/i18n/internationalize.dart';
import 'custom_exception.dart';

sealed class AppException<T extends Object?> extends CustomException<T> {
  const AppException({super.data});
}

final class GenericException extends AppException {
  @override
  String get title => Internationalize.errorGenericTitle;

  @override
  String get message => Internationalize.errorGenericMessage;

  const GenericException();
}

final class InvalidLevelException extends AppException<String> {
  @override
  String get title => Internationalize.errorInvalidLevelTitle;

  @override
  String get message => Internationalize.errorInvalidLevelMessage(reason: data!);

  const InvalidLevelException({required String super.data});
}

final class UnknownTreeKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownTreeKindTitle;

  @override
  String get message => Internationalize.errorUnknownTreeKindMessage(detail: data!);

  const UnknownTreeKindException({required String super.data});
}

final class UnknownDecorationKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownDecorationKindTitle;

  @override
  String get message => Internationalize.errorUnknownDecorationKindMessage(detail: data!);

  const UnknownDecorationKindException({required String super.data});
}

final class UnknownItemKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownItemKindTitle;

  @override
  String get message => Internationalize.errorUnknownItemKindMessage(detail: data!);

  const UnknownItemKindException({required String super.data});
}

final class NoGameInProgressException extends AppException {
  @override
  String get title => Internationalize.errorNoGameInProgressTitle;

  @override
  String get message => Internationalize.errorNoGameInProgressMessage;

  const NoGameInProgressException();
}
