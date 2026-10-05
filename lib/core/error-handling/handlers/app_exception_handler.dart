import 'package:injectable/injectable.dart';

import '../exceptions/app_exceptions.dart';

@Injectable()
class AppExceptionHandler {
  AppException<Object?> handle({required Object? exception, StackTrace? stackTrx}) {
    if (exception is AppException) {
      return exception;
    }

    return const GenericException();
  }
}
