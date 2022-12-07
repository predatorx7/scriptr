import 'dart:io';

import 'package:logging/logging.dart';

final logging = Logger('scriptr');

extension LoggerUtils on Logger {
  Logger call(String childName) {
    return Logger('$fullName.$childName');
  }
}

Level getLoggerLevelFromDebug(String debug) {
  if (debug == '*') {
    return Level.ALL;
  } else if (int.tryParse(debug) != null) {
    final value = int.parse(debug);
    if (value >= 0 && value < Level.LEVELS.length) {
      return Level.LEVELS[value];
    } else {
      return Level('CUSTOM', value);
    }
  } else {
    return Level.INFO;
  }
}

void setupLogger(List<String> arguments) {
  hierarchicalLoggingEnabled = true;

  final debug = Platform.environment['DEBUG'];
  final isVerbose = debug != null && debug.isNotEmpty;

  if (isVerbose) {
    logging.level = getLoggerLevelFromDebug(debug);
  } else {
    logging.level = Level.OFF;
  }

  logging.onRecord.listen(onLogs);
}

void onLogs(LogRecord event) {
  print(event.toString());
  if (event.error != null) {
    print(event.error);
    print(event.stackTrace);
  }
}
