import 'package:farming/core/services/logging/source/logger.dart';

class LoggedErrorFake {
  final String message;
  final String? header;
  final StackTrace? stackTrace;

  const LoggedErrorFake({required this.message, this.header, this.stackTrace});
}

class LoggerFake implements Logger {
  final List<LoggedErrorFake> errors = [];

  @override
  void error({required String message, String? header, StackTrace? stackTrace}) {
    errors.add(LoggedErrorFake(message: message, header: header, stackTrace: stackTrace));
  }

  @override
  void success({required String message, String? header}) {}

  @override
  void warning({required String message, String? header}) {}

  @override
  void info({required String message, String? header}) {}

  @override
  void debug({required String message, String? header}) {}
}
