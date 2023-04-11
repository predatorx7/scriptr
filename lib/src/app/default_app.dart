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
import 'command.dart';

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
    final isVerboseModeAvailable =
        app.metadata.options?.isVerboseModeAvailable != false;

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
    final scriptAction = ScriptAction(app, logger);

    late final helpMessage = scriptAction.createGlobalHelpMessage();

    if (arguments.isEmpty) {
      logger.info(helpMessage);
      return;
    }

    logger.finest(arguments);

    return evaluateCommandArguments(
      scriptAction,
      app.commands,
      arguments,
    );
  }

  Future<void> evaluateCommandArguments(
    ScriptAction scriptAction,
    Map<String, ScriptCommand> commandsMap,
    Arguments arguments,
  ) async {
    final targetCommand = findScriptCommand(commandsMap, arguments);

    if (targetCommand != null) {
      scriptAction.logger.info(targetCommand.toJson());
      final functions = targetCommand.functions;
      if (functions != null && functions.isNotEmpty) {
        for (final function in functions) {
          if (function.canCall(targetCommand, arguments)) {
            return function(scriptAction, targetCommand, arguments);
          }
        }
      }
      final subCommands = targetCommand.subCommands;
      if (subCommands != null) {
        return evaluateCommandArguments(
          scriptAction,
          Map.fromEntries(
            subCommands.map(
              (e) => MapEntry(e.name, e),
            ),
          ),
          arguments,
        );
      }
      scriptAction.logger.severe(
        scriptAction.notMatchedMessageIn(targetCommand),
      );
    } else {
      scriptAction.logger.severe(
        scriptAction.noCommandsMatchedMessage(),
      );
    }
  }

  ScriptCommand? findScriptCommand(
    Map<String, ScriptCommand> commandsMap,
    Arguments arguments,
  ) {
    for (final arg in arguments) {
      if (arg.isPosition) {
        final posArg = arg as PositionalArgument;
        ScriptCommand? command = commandsMap[posArg.value];
        if (command != null &&
            command.section?.info?.isPositionalEnabled != false) {
          return command;
        }

        final matchingCommands = commandsMap.values.where(
          (it) => it.section?.alias?.contains(posArg.value) == true,
        );
        if (matchingCommands.isNotEmpty) {
          command = matchingCommands.first;
          if (command.section?.info?.isPositionalAbbreviationEnabled != false) {
            return command;
          }
        }
      }

      if (arg.isAbbreviatedNamed) {
        final abbrArg = arg as NamedAbbreviatedArgument;
        final matchingCommands = commandsMap.values.where(
          (it) => it.section?.alias?.contains(abbrArg.name) == true,
        );
        ScriptCommand? command;
        if (matchingCommands.isNotEmpty) {
          command = matchingCommands.first;
          if (command.section?.info?.isNamedAbbreviationEnabled != false) {
            return command;
          }
        }
      }
      if (arg.isNamed) {
        final namedArg = arg as NamedArgument;
        ScriptCommand? command = commandsMap[namedArg.name];
        if (command != null && command.section?.info?.isNamedEnabled != false) {
          return command;
        }
      }
    }
    return null;
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
