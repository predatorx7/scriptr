import 'dart:async';

import 'package:colorize/colorize.dart';
import 'package:logging/logging.dart';

import 'package:scriptr/src/logging.dart';
import 'package:scriptr/src/io/cli.dart';
import 'package:scriptr/src/runner.dart';
import 'package:scriptr/src/utils/config_file.dart';

import '../arguments/arguments.dart';
import '../data/data.dart';
import 'actions.dart';

typedef CommandSearchResult = ({
  ScriptCommand command,
  Argument argument,
});

class DefaultScriptAppRunner extends ScriptAppRunner {
  const DefaultScriptAppRunner(this.args);

  final List<String> args;

  @override
  Future<ScriptApp> createApp() async {
    final scriptContent = await getConfigContent(args);
    final config = getConfigContentAsMap(scriptContent);

    return ScriptApp.fromJson(config);
  }

  @override
  FutureOr<Arguments> parseArguments(ScriptApp app) {
    return Argument.parseApplicationArguments(args);
  }

  @override
  FutureOr<void> run(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
    CliIO io,
  ) async {
    setLoggerLevel(app, arguments, logger);

    final scriptAction = AppActions(app, logger, io);

    if (arguments.isEmpty) {
      logger.info(scriptAction.createGlobalHelpMessage());
      return;
    }

    logger.finest('parsed arguments: $arguments');

    return evaluateCommandArguments(
      scriptAction,
      app.commands,
      arguments,
    );
  }

  void setLoggerLevel(
    ScriptApp app,
    Arguments arguments,
    Logger logger,
  ) {
    final isVerboseModeAvailable =
        app.metadata.options?.isVerboseModeAvailable != false;

    if (!isDebugVerboseLoggingEnabled && isVerboseModeAvailable) {
      logger.level = Level.INFO;
      final isVerbose = arguments.containsNamedParameter(
        Parameter.named('verbose', 'v'),
      );
      if (isVerbose) {
        logger.level = Level.FINE;
      }
    }

    logger.fine({
      'isVerboseModeAvailable': isVerboseModeAvailable,
      'isDebugVerboseLoggingEnabled': isDebugVerboseLoggingEnabled,
      'logger.level': logger.level,
    });
  }

  Future<void> evaluateCommandArguments(
    AppActions scriptAction,
    Map<String, ScriptCommand> commandsMap,
    Arguments arguments, {
    List<ScriptCommand> parentCommands = const [],
  }) async {
    final CommandSearchResult? targetCommandResult = findScriptCommand(
      parentCommands,
      commandsMap,
      arguments,
    );
    logger.info({'targetCommandResult': targetCommandResult});
    late final currentCommands = [
      ...parentCommands,
    ];
    if (targetCommandResult != null) {
      final targetCommand = targetCommandResult.command;
      currentCommands.add(targetCommand);
      logger.info(targetCommand.toJson());

      final subCommands = targetCommand.subCommands;

      if (subCommands != null && subCommands.isNotEmpty) {
        return evaluateCommandArguments(
          scriptAction,
          Map.fromEntries(
            subCommands.map(
              (e) => MapEntry(e.name, e),
            ),
          ),
          arguments,
          parentCommands: currentCommands,
        );
      }

      final functions = targetCommand.functions;
      if (functions != null && functions.isNotEmpty) {
        final exe = targetCommand.section?.exe;
        if (exe != null) scriptAction.addExe(exe);
        for (final function in functions) {
          final resolvedParameters = scriptAction.resolveParameters(
            function.parameters,
            arguments,
            targetCommandResult.argument,
          );
          if (resolvedParameters == null) continue;
          final exe = function.executable;
          if (exe != null) {
            scriptAction.addExe(exe);
          }
          await scriptAction.invokeFunction(
            function,
            resolvedParameters,
          );
          return;
        }
        if (exe != null) scriptAction.popExe();
      }
    }
    if (currentCommands.isNotEmpty) {
      scriptAction.logger.info(
        scriptAction.createScriptCommandHelpMessage(currentCommands),
      );
    }
    scriptAction.logger.severe(
      scriptAction.notMatchedMessageIn(currentCommands, arguments),
    );
  }

  CommandSearchResult? findScriptCommand(
    List<ScriptCommand> parentCommands,
    Map<String, ScriptCommand> commandsMap,
    Arguments arguments,
  ) {
    logger.info({
      'argument.len': arguments.length,
      'arguments': arguments,
    });
    for (final arg in arguments) {
      if (arg.isPosition) {
        final posArg = arg as PositionalArgument;
        ScriptCommand? command = commandsMap[posArg.value];
        if (command != null &&
            command.section?.info?.isPositionalEnabled != false) {
          return (command: command, argument: arg);
        }

        final matchingCommands = commandsMap.values.where(
          (it) => it.section?.alias?.contains(posArg.value) == true,
        );
        if (matchingCommands.isNotEmpty) {
          command = matchingCommands.first;
          if (command.section?.info?.isPositionalAbbreviationEnabled != false) {
            return (command: command, argument: arg);
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
            return (command: command, argument: arg);
          }
        }
      }
      if (arg.isNamed) {
        final namedArg = arg as NamedArgument;
        ScriptCommand? command = commandsMap[namedArg.name];
        if (command != null && command.section?.info?.isNamedEnabled != false) {
          return (command: command, argument: arg);
        }
      }
    }
    return null;
  }

  static final _log = logging('DefaultSciptrApp.onLogs');

  @override
  void onLogs(LogRecord event, CliIO io) {
    final isError = event.level >= Level.SEVERE;
    if (isDebugVerboseLoggingEnabled && _log.isLoggable(event.level)) {
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
        io.writelnError(errorMessage);
      } else {
        String output = message;
        final level = event.level;
        if (level >= Level.SEVERE) {
          output = Colorize(message).red().toString();
        } else if (level >= Level.WARNING) {
          output = Colorize(message).yellow().toString();
        } else if (level >= Level.INFO) {
          output = message;
        } else if (level >= Level.CONFIG) {
          output = Colorize(message).blue().toString();
        } else if (level >= Level.FINE) {
          output = Colorize(message).lightYellow().toString();
        }
        io.writeln(output);
      }
    }
  }
}
