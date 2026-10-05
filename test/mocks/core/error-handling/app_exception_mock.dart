import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';

abstract final class AppExceptionMock {
  static const InvalidLevelException invalidLevel = InvalidLevelException(data: 'missing width');
}
