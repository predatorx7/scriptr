import 'dart:io';

import 'package:logging/logging.dart';

final logging = Logger('scriptr');

extension LoggerUtils on Logger {
  Logger call(String childName) {
    return Logger('$fullName.$childName');
  }
}

final bool isVerboseLoggingEnabled = () {
  final debug = Platform.environment['DEBUG'];
  final isVerbose = debug != null && debug.isNotEmpty && debug == '*';
  return isVerbose;
}();

const _defaultLoggerLevel = Level.WARNING;

Level _getLoggerLevelFromDebug() {
  final debug = Platform.environment['DEBUG'];
  if (debug == '*') {
    return Level.ALL;
  } else if (debug == null || debug.isEmpty) {
    return _defaultLoggerLevel;
  } else {
    final debugInt = int.tryParse(debug);
    for (final level in Level.LEVELS) {
      if (level.value == debugInt || level.name == debug) return level;
    }
    if (debugInt == null) return Level.INFO;
    return Level('CUSTOM', debugInt);
  }
}

final Level _loggerLevelFromDebug = () {
  if (isVerboseLoggingEnabled) {
    return _getLoggerLevelFromDebug();
  } else {
    return _defaultLoggerLevel;
  }
}();

void _onLogs(LogRecord event) {
  final message = event.object?.toString() ?? event.message;
  final level = event.level;
  final loggerName = event.loggerName;
  final msg = message.isNotEmpty && message != 'null' ? message : '';
  print("[${level.name}] $loggerName: $msg");
  if (event.error != null) {
    print(event.error);
    print(event.stackTrace);
  }
}

void setupLogger() {
  hierarchicalLoggingEnabled = true;

  logging.level = _loggerLevelFromDebug;

  logging.onRecord.listen(_onLogs);
}
