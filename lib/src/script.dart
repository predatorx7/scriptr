import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'app/default_app.dart';
import 'logging.dart';

class ApplicationContext {
  ApplicationContext(
    this.arguments,
    this.output,
    this.errorOutput,
  ) : logger = Logger('ApplicationContext') {
    startLogging();
  }

  final List<String> arguments;

  final IOSink output;

  final IOSink errorOutput;

  final Logger logger;

  StreamSubscription<LogRecord>? logRecordSubscription;

  Future<void> startLogging() async {
    await cancelLogging();
    logger.level = Level.INFO;
    logRecordSubscription = logger.onRecord.listen(onLogs);
  }

  static final _log = logging('ApplicationContext.onLogs');

  void onLogs(LogRecord event) {
    final isError = event.level >= Level.SEVERE;
    if (isVerboseLoggingEnabled && _log.isLoggable(event.level)) {
      _log.log(
        isError ? Level.SEVERE : Level.INFO,
        event.message,
        event.error,
        event.stackTrace,
        event.zone,
      );
    } else {
      final message = event.message;

      if (isError) {
        errorOutput.writeln([
          if (message.isNotEmpty && message != 'null') message,
          event.error,
        ].join('\n'));
      } else {
        output.writeln(message);
      }
    }
  }

  Future<void> cancelLogging() {
    final subscription = logRecordSubscription;
    if (subscription == null) return Future.value(null);
    return subscription.cancel();
  }
}

typedef ScriptRunnerAppCreateCallback = Scriptr Function(
  ApplicationContext data,
);

abstract class Scriptr {
  final ApplicationContext context;

  const Scriptr(
    this.context,
  );

  void run();
}

Future<void> runApp(
  List<String> args, {
  ScriptRunnerAppCreateCallback build = DefaultSciptrApp.new,
  IOSink? output,
  IOSink? errorOutput,
}) async {
  setupLogger();

  final context = ApplicationContext(
    args,
    output ?? stdout,
    errorOutput ?? stderr,
  );

  final builtRunner = build(context);

  runZonedGuarded(builtRunner.run, (error, stack) {
    context.logger.severe(null, error, stack);
  });
}
