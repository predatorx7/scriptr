import 'dart:async';

import 'package:logging/logging.dart';

import 'app/app.dart';
import 'logger/cli.dart';
import 'logging.dart';
import 'scriptr_args.dart';

abstract class ScriptAppRunner {
  const ScriptAppRunner();

  /// Creates a [ScriptApp] from a scriptr source file like json, yaml.
  FutureOr<ScriptApp> createApp();

  /// Parse launch arguments with [ScriptApp]
  FutureOr<Arguments> parseArguments(ScriptApp app);

  void onLogs(LogRecord event, CliIO io);

  /// Runs [app] with [arguments].
  FutureOr<void> run(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
    CliIO io,
  );
}

Future<void> runApp(
  ScriptAppRunner runner, {
  CliIO? io,
}) async {
  setupLogger();

  final cliIO = io ?? CliIO();

  final logger = Logger('ScriptAppRunner');

  final subscription = logger.onRecord.listen((event) {
    runner.onLogs(event, cliIO);
  });

  return runZonedGuarded(() async {
    final app = await runner.createApp();
    final parsedArguments = await runner.parseArguments(app);
    await runner.run(app, parsedArguments, logger, cliIO);
    subscription.cancel();
  }, (error, stack) {
    logger.severe(null, error, stack);
  });
}
