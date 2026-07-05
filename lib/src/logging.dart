import 'package:logger/logger.dart';

/// Process-wide logger shared by clean_signals classes.
///
/// Register your app's configured [Logger] once at startup:
///
/// ```dart
/// CleanSignalsLogger.instance.register(Logger(level: Level.debug));
/// ```
class CleanSignalsLogger {
  CleanSignalsLogger._();

  static final CleanSignalsLogger instance = CleanSignalsLogger._();

  Logger logger = Logger(
    level: Level.warning,
    printer: PrettyPrinter(methodCount: 0),
  );

  void register(Logger logger) => this.logger = logger;
}
