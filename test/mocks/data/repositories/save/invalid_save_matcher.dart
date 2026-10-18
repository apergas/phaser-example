import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/error-handling/exceptions/app_exceptions.dart';

Matcher throwsInvalidSave(String data) {
  return throwsA(isA<InvalidSaveException>().having((exception) => exception.data, 'data', data));
}
