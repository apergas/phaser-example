abstract interface class Logger {
  void success({required String message, String? header});
  void error({required String message, String? header, StackTrace? stackTrace});
  void warning({required String message, String? header});
  void info({required String message, String? header});
  void debug({required String message, String? header});
}
