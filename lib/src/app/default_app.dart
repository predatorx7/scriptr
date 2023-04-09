import 'dart:async';

import 'package:colorize/colorize.dart';
import 'package:logging/logging.dart';
import 'package:scriptr/src/logging.dart';
import 'package:scriptr/src/scriptr_args.dart';
import 'package:scriptr/src/scriptr_params.dart';
import 'package:scriptr/src/utils/booleans.dart';

import '../script.dart';
import '../scriptr_utils.dart';
import 'actions.dart';
import 'app.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.context);

  @override
  Future<ScriptApp> createApp(List<String> arguments) async {
    final scriptContent = await getScriptContent(arguments);
    final config = getScriptContentAsMap(scriptContent);

    return ScriptApp.fromJson(config);
  }

  @override
  FutureOr<Arguments> parseArguments(ScriptApp app, List<String> arguments) {
    return Argument.parseApplicationArguments(context.arguments);
  }

  @override
  FutureOr<void> onCreate(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
  ) {
    final isVerbose = arguments.containsNamedParameter(
      Parameter.named('verbose', 'v'),
    );
    final isVerboseModeAvailable = isTrueIfTrueOrNull(
      app.metadata.options?.isVerboseModeAvailable,
    );

    void setVerboseMode(bool isVerboseMode) {
      if (isVerboseMode) {
        logger.level = Level.ALL;
      } else {
        logger.level = Level.INFO;
      }
    }

    setVerboseMode(isVerbose && isVerboseModeAvailable);
  }

  @override
  FutureOr<void> run(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
  ) async {
    final scriptAction = ScriptAction(app);

    late final helpMessage = scriptAction.createGlobalHelpMessage();

    if (arguments.isEmpty) {
      logger.info(helpMessage);
      return;
    }

    logger.finest(arguments);
    logger.severe(scriptAction.noCommandsMatchedMessage());
  }

  static final _log = logging('DefaultSciptrApp.onLogs');

  @override
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
        String errorMessage = [
          if (message.isNotEmpty && message != 'null') message,
          if (event.error != null) event.error,
        ].join('\n');
        errorMessage = Colorize(errorMessage).red().toString();
        context.errorOutput.writeln(errorMessage);
      } else {
        String output = message;
        final level = event.level.value;
        if (level >= 1000) {
          output = Colorize(message).red().toString();
        } else if (level >= 900) {
          output = Colorize(message).yellow().toString();
        } else if (level >= 800) {
          output = Colorize(message).blue().toString();
        } else if (level >= 700) {
          output = Colorize(message).lightYellow().toString();
        }
        context.output.writeln(output);
      }
    }
  }
}
