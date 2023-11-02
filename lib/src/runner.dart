import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'arguments/arguments.dart';
import 'data/data.dart';
import 'io/cli.dart';
import 'logging.dart';

abstract class ScriptAppRunner {
  ScriptAppRunner();

  /// Creates a [ScriptApp] from a scriptr source file like json, yaml.
  /// The App returned by this is provided to [parseArguments].
  FutureOr<ScriptApp> createApp();

  /// Parse launch arguments with [ScriptApp].
  /// This is invoked after [app] is created using [createApp].
  FutureOr<Arguments> parseArguments(ScriptApp app);

  /// Runs the [app] with [arguments]. [logger] & [io] is used to provide
  /// information CLI output and get input.
  FutureOr<void> run(
    ScriptApp app,
    Arguments arguments,
    CliIO io,
  );

  Logger? _logger;

  Logger get logger => _logger!;

  /// This ataches listeners to [logger] to stream logs. [cliIO] can be used by this to emit logs on
  /// [cliIO]'s [CliIO.stdout]. This decides how and where logs are used. generally, logs at level
  /// [Level.FINE] or below may contain information about how the ScriptAppRunner is running and are for developers.
  ///
  /// Logs at [Level.CONFIG] is for any verbose logs for the CLI App (Can be seen by using `--verbose` in [DefaultScriptAppRunner]), and
  /// logs at [Level.INFO] and above is for the consumer of this CLI.
  ///
  /// [Stacktrace] is only shown for [DefaultScriptAppRunner] for when cli arguments include `--scriptr-debug`.
  @mustCallSuper
  void attachLogger(Logger logger, CliIO cliIO) {
    _logger = logger;
  }
}

Future<void> runApp(
  ScriptAppRunner runner, {
  CliIO? io,
}) async {
  final cliIO = io ?? CliIO();

  hierarchicalLoggingEnabled = true;

  runner.attachLogger(mainLogger, cliIO);

  final runnerLogger = mainLogger('runApp');

  return runZonedGuarded(() async {
    final app = await runner.createApp();
    final parsedArguments = await runner.parseArguments(app);
    await runner.run(app, parsedArguments, cliIO);
  }, (error, stack) {
    runnerLogger.severe('Application crashed', error, stack);
  });
}
