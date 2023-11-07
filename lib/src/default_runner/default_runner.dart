import 'dart:async';

import 'package:io/ansi.dart' as ansi;
import 'package:logging/logging.dart';

import 'package:scriptr/src/io/cli.dart';
import 'package:scriptr/src/logging.dart' show getPlainTextStringFrom;
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
  DefaultScriptAppRunner(this.args);

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
    CliIO io,
  ) async {
    updateLoggerLevelForVerbose(app, arguments);

    final scriptAction = AppActions(app, logger, io);

    if (arguments.isEmpty) {
      logger.info(scriptAction.createGlobalHelpMessage());
      return;
    }

    logger.finer('parsed arguments: $arguments');

    return evaluateCommandArguments(
      scriptAction,
      app.commands,
      arguments,
    );
  }

  void updateLoggerLevelForVerbose(
    ScriptApp app,
    Arguments arguments,
  ) {
    if (logger.level < Level.CONFIG) return;

    final isVerboseModeAvailable = app.options.isVerboseModeAvailable != false;
    if (!isVerboseModeAvailable) return;

    final isVerbose = arguments.containsNamedParameter(
      Parameter.named('verbose', 'v'),
    );

    if (!isVerbose) return;

    logger.level = Level.CONFIG;
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
    logger.fine({'targetCommandResult': targetCommandResult});
    late final currentCommands = [
      ...parentCommands,
    ];
    if (targetCommandResult != null) {
      final targetCommand = targetCommandResult.command;
      currentCommands.add(targetCommand);
      logger.fine('targetCommand as json: ${targetCommand.toJson()}');

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
          late final Map<String, Object?> resolvedParameters;

          try {
            resolvedParameters = scriptAction.resolveParameters(
              function.parameters,
              arguments,
              targetCommandResult.argument,
              true,
            );
          } on ScriptrValueTypeError {
            resolvedParameters = {};
          }

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
      scriptAction.logger.severe(
        scriptAction.notMatchedMessageIn(currentCommands, arguments),
      );
    } else {
      // Could not find a command named "".
      scriptAction.logger.severe(
        scriptAction.notMatchedMessageIn(currentCommands, arguments),
      );
      scriptAction.logger.info(
        scriptAction.createGlobalHelpMessage(),
      );
    }
  }

  CommandSearchResult? findScriptCommand(
    List<ScriptCommand> parentCommands,
    Map<String, ScriptCommand> commandsMap,
    Arguments arguments,
  ) {
    logger.finer({
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

  @override
  void attachLogger(Logger logger, CliIO cliIO) {
    super.attachLogger(logger, cliIO);

    final isScriptrLoggingEnabled = args.any(
      (e) => e.toLowerCase().contains('--scriptr-logging'),
    );

    logger.level = isScriptrLoggingEnabled ? Level.ALL : Level.INFO;

    logger.onRecord.listen((event) {
      _onLogs(event, cliIO);
    });
  }

  void _onLogs(LogRecord event, CliIO io) {
    final isError = event.level >= Level.SEVERE;
    final message = event.message;

    if (isError) {
      String errorMessage = [
        if (message.isNotEmpty && message != 'null') message,
        if (event.error != null) event.error,
      ].join('\n');
      errorMessage = ansi.red.wrap(errorMessage) ?? '';
      io.writelnError(errorMessage);
    } else {
      final String output;
      final level = event.level;
      if (level >= Level.SEVERE) {
        output = ansi.red.wrap(message) ?? '';
      } else if (level >= Level.WARNING) {
        output = ansi.yellow.wrap(message) ?? '';
      } else if (level >= Level.INFO) {
        output = message;
      } else if (level >= Level.CONFIG) {
        output = ansi.blue.wrap(message) ?? '';
      } else {
        output = ansi.lightYellow.wrap(getPlainTextStringFrom(event)) ?? '';
      }
      io.writeln(output);
    }
  }
}
