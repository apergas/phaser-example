import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';

abstract final class AppExceptionMock {
  static const InvalidLevelException invalidLevel = InvalidLevelException(data: 'missing width');

  static const UnknownTreeKindException unknownTreeKind = UnknownTreeKindException(data: 'tree-3: "palm"');

  static const NoGameInProgressException noGameInProgress = NoGameInProgressException();
}
