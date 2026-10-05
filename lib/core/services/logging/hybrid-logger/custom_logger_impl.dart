import 'package:hybrid_logger/hybrid_logger.dart';
import 'package:injectable/injectable.dart';

import '../source/logger.dart';

@Singleton(as: Logger)
class CustomLoggerImpl implements Logger {
  final HybridLogger _hybridLogger = HybridLogger(
    settings: HybridSettings(type: LogTypeEntity.debug, maxLineWidth: 50),
  );

  @override
  void debug({required String message, String? header}) {
    _hybridLogger.debug(message, header: header);
  }

  @override
  void error({required String message, String? header, StackTrace? stackTrace}) {
    _hybridLogger.error(message, header: header, stack: stackTrace);
  }

  @override
  void info({required String message, String? header}) {
    _hybridLogger.info(message, header: header);
  }

  @override
  void success({required String message, String? header}) {
    _hybridLogger.success(message, header: header);
  }

  @override
  void warning({required String message, String? header}) {
    _hybridLogger.warning(message, header: header);
  }
}
