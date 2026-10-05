import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';

void main() {
  late AppExceptionHandler handler;

  setUp(() {
    handler = AppExceptionHandler();
  });

  test('testWhenHandlingAnAppExceptionThenItIsReturnedUnchanged', () {
    // given
    const exception = InvalidLevelException(data: 'missing width');

    // when
    final handled = handler.handle(exception: exception);

    // then
    expect(identical(handled, exception), isTrue);
  });

  test('testWhenHandlingAnUnknownErrorThenItBecomesAGenericException', () {
    // given
    final error = StateError('boom');

    // when
    final handled = handler.handle(exception: error, stackTrx: StackTrace.current);

    // then
    expect(handled, isA<GenericException>());
  });

  test('testWhenHandlingNullThenItBecomesAGenericException', () {
    // given
    const Object? error = null;

    // when
    final handled = handler.handle(exception: error);

    // then
    expect(handled, isA<GenericException>());
  });

  test('testWhenALevelExceptionCarriesDetailsThenTheyAreItsData', () {
    // given
    const exception = UnknownTreeKindException(data: 'tree-3: "palm"');

    // when
    final hasData = exception.hasData();

    // then
    expect(hasData, isTrue);
    expect(exception.data, 'tree-3: "palm"');
  });
}
