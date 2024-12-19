import 'package:logger/logger.dart';

export 'package:logger/logger.dart';

class BaseCoreLogger {
  static final BaseCoreLogger _singleton = BaseCoreLogger._internal();

  Logger? _logger;

  Logger get logger => _logger ??= Logger();

  BaseCoreLogger._internal();

  static BaseCoreLogger get instance => _singleton;

  void init({
    LogFilter? filter,
    LogPrinter? printer,
    LogOutput? output,
  }) {
    _logger = Logger(
      filter: filter,
      printer: printer,
      output: output,
    );
  }
}
