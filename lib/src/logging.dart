import 'package:logger/logger.dart';

/// Process-wide logger shared by base_core classes.
///
/// Register your app's configured [Logger] once at startup:
///
/// ```dart
/// BaseCoreLogger.instance.register(Logger(level: Level.debug));
/// ```
class BaseCoreLogger {
  BaseCoreLogger._();

  static final BaseCoreLogger instance = BaseCoreLogger._();

  Logger logger = Logger(
    level: Level.warning,
    printer: PrettyPrinter(methodCount: 0),
  );

  void register(Logger logger) => this.logger = logger;
}
