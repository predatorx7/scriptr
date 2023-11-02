import 'package:logging/logging.dart';

final mainLogger = Logger('scriptr');

extension LoggerUtils on Logger {
  Logger call(String childName) {
    return Logger('$fullName.$childName');
  }
}

String getPlainTextStringFrom(LogRecord event) {
  final message = event.object?.toString() ?? event.message;
  final level = event.level;
  final loggerName = event.loggerName;
  final msg = message.isNotEmpty && message != 'null' ? message : '';
  final buffer = StringBuffer();
  buffer.writeln("[${level.name}] $loggerName: $msg");
  if (event.error != null) {
    buffer.writeln(event.error);
    buffer.writeln(event.stackTrace);
  }
  return buffer.toString();
}
