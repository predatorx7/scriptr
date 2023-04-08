import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'app/app.dart';
import 'app/default_app.dart';
import 'logging.dart';
import 'scriptr_args.dart';

class ApplicationContext {
  ApplicationContext(
    this.arguments,
    this.output,
    this.errorOutput,
  ) : logger = Logger('ApplicationContext');

  final List<String> arguments;

  final IOSink output;

  final IOSink errorOutput;

  final Logger logger;

  StreamSubscription<LogRecord>? logRecordSubscription;

  Future<void> startLogging(void Function(LogRecord)? onLogs) async {
    await cancelLogging();
    logRecordSubscription = logger.onRecord.listen(onLogs);
  }

  Future<void> cancelLogging() {
    final subscription = logRecordSubscription;
    if (subscription == null) return Future.value(null);
    return subscription.cancel();
  }
}

typedef ScriptRunnerAppCreateCallback = Scriptr Function(
  ApplicationContext context,
);

abstract class Scriptr {
  const Scriptr(this.context);

  final ApplicationContext context;

  FutureOr<ScriptApp> createApp(List<String> arguments);

  FutureOr<Arguments> parseArguments(ScriptApp app, List<String> arguments);

  FutureOr<void> onCreate(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
  );

  void onLogs(LogRecord event);

  FutureOr<void> run(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
  );
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

  runZonedGuarded(() async {
    final builtRunner = build(context);
    final app = await builtRunner.createApp(context.arguments);
    final parsedArguments = await builtRunner.parseArguments(
      app,
      context.arguments,
    );
    await builtRunner.onCreate(app, parsedArguments, context.logger);
    await context.startLogging(builtRunner.onLogs);
    await builtRunner.run(app, parsedArguments, context.logger);
  }, (error, stack) {
    context.logger.severe(null, error, stack);
  });
}
