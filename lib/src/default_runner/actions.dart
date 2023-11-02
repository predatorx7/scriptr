import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:scriptr/scriptr.dart';
import 'package:scriptr/src/io/cli.dart';
import 'package:scriptr/src/utils/arguments.dart';

import '../arguments/arguments.dart';
import '../utils/exe.dart';
import '../utils/interpolations.dart';
import '../data/data.dart';
import 'dart:math' as math;

import '../utils/string_print.dart';

class AppActions {
  final ScriptApp app;
  final Logger logger;
  final CliIO io;

  AppActions(
    this.app,
    this.logger,
    this.io,
  ) {
    final exe = app.options.exe;
    if (exe != null) {
      addExe(exe);
    }
    final exeMethods = app.options.exeMethods;
    if (exeMethods != null) {
      addExeMethods(exeMethods);
    }
  }

  String createGlobalHelpMessage() {
    final buffer = StringBuffer();
    final about = app.metadata;
    final aboutMap = about.toJson();
    final description = app.metadata.description;

    if (description != null && description.isNotEmpty) {
      buffer.writeln(interpolateValues(description.trim(), aboutMap));
      buffer.writeln();
    }

    final appExecutableName = app.metadata.name?.toLowerCase() ?? 'app';

    buffer.writeln(
      'Usage: $appExecutableName <command> [options]',
    );
    buffer.writeln();
    buffer.writeln('Available commands:');
    buffer.writeln();

    final commandEntries = app.commands.entries;
    final maxLengthOfName = commandEntries
        .map((e) => e.key.length)
        .reduce((value, element) => math.max(value, element));

    for (final command in commandEntries) {
      final commandName = command.key;
      final description =
          command.value.section?.info?.description?.trim() ?? '';
      buffer.writeln(
        '  ${commandName.padRight(maxLengthOfName)}  ${interpolateValues(description.trim(), aboutMap)}',
      );
    }

    buffer.writeln();
    buffer.writeln(
      'Run "$appExecutableName help <something>" to read about a specific subcommand or concept.',
    );

    return buffer.toString();
  }

  String createScriptCommandHelpMessage(List<ScriptCommand> targetCommands) {
    final buffer = StringBuffer();
    final about = app.metadata;
    final aboutMap = about.toJson();
    final targetCommand = targetCommands.last;
    final cmdInfo = targetCommand.section?.info;

    if (cmdInfo != null) {
      final description = cmdInfo.description;
      if (description != null && description.isNotEmpty) {
        buffer.writeln(interpolateValues(description.trim(), aboutMap));
        buffer.writeln();
      }
    }

    final appExecutableName = app.metadata.name?.toLowerCase() ?? 'app';
    final parentCommands =
        targetCommands.where((value) => value != targetCommand);
    final parentFullCommandName = [
      appExecutableName,
      ...parentCommands.map((e) => e.name.toLowerCase())
    ].join(' ');
    final fullCommandName = targetCommands
        .map(
          (e) => e.name.toLowerCase(),
        )
        .join(' ');

    buffer.writeln(
      'Usage: $appExecutableName $fullCommandName <arguments> [options]',
    );
    buffer.writeln();

    final commandEntries = targetCommand.subCommands;
    if (commandEntries != null && commandEntries.isNotEmpty) {
      buffer.writeln('Available commands:');
      buffer.writeln();
      final maxLengthOfName = commandEntries
          .map((e) => e.name.length)
          .fold(0, (value, element) => math.max(value, element));

      for (final command in commandEntries) {
        final commandName = command.name;
        final description = command.section?.info?.description?.trim() ?? '';
        buffer.writeln(
          '  ${commandName.padRight(maxLengthOfName)}  ${interpolateValues(description.trim(), aboutMap)}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln(
      'Run "$parentFullCommandName help <something>" to read about a specific subcommand or concept.',
    );

    return buffer.toString();
  }

  String notMatchedMessageIn(
    List<ScriptCommand> commands,
    Arguments arguments,
  ) {
    final buffer = StringBuffer();
    final targetCommand = commands.isNotEmpty ? commands.first : null;
    final appExecutableName = app.metadata.name?.toLowerCase() ?? 'app';
    final parentCommands = commands.where((value) => value != targetCommand);
    final parentFullCommandName = [
      appExecutableName,
      ...parentCommands.map((e) => e.name.toLowerCase())
    ].join(' ');
    final fullCommandName = commands.map((e) => e.name.toLowerCase()).join(' ');
    buffer.writeln();
    if (targetCommand != null) {
      final functions = targetCommand.functions;
      final seeText =
          'See \'$parentFullCommandName help ${targetCommand.name}\'.';
      if (functions != null && functions.isNotEmpty) {
        final args = arguments.toList().sublist(1);
        if (args.isNotEmpty) {
          buffer.writeln(
            '$appExecutableName: Unknown arguments `${args.toSpaceSeparatedString()}` for $fullCommandName command. $seeText',
          );
        } else {
          buffer.writeln(
            '$appExecutableName: No arguments for $fullCommandName command. $seeText',
          );
        }
      } else {
        buffer.writeln(
          '$appExecutableName: not a $fullCommandName sub-command. $seeText',
        );
      }
    } else if (arguments.isNotEmpty) {
      final seeText = 'See \'$parentFullCommandName help\'.';
      buffer.writeln(
        '$appExecutableName: Could not find a command named "${arguments.toSpaceSeparatedString()}". $seeText',
      );
    } else {
      final seeText = 'See \'$parentFullCommandName help\'.';
      buffer.writeln(
        '$appExecutableName: not a $appExecutableName command. $seeText',
      );
    }
    return buffer.toString();
  }

  Map<String, Object?> resolveParameters(
    Map<String, List<Type>> parameters,
    Arguments arguments,
    Argument commandArgument,
    bool strict,
  ) {
    final parameterValues = <String, Object?>{};
    for (final parameter in parameters.entries) {
      bool didGetMatchedArgument = false;
      for (final argument in arguments) {
        if (!didGetMatchedArgument) {
          didGetMatchedArgument = argument == commandArgument;
        } else if (argument != commandArgument &&
            argument is PositionalArgument) {
          final value = resolveValueForTypes(argument.value, parameter.value);
          parameterValues[parameter.key] = value;
          break;
        }
        if (argument is NamedArgument && argument.name == parameter.key) {
          if (argument.arguments.isNotEmpty) {
            final value = resolveValueForTypes(
              argument.arguments.first.value,
              parameter.value,
            );
            parameterValues[parameter.key] = value;
            break;
          } else {
            final value = resolveValueForTypes(
              'true', // because value is present but has no arguments
              parameter.value,
            );
            if (value is bool) {
              parameterValues[parameter.key] = value;
            }
          }
        }
      }
      if (parameterValues[parameter.key] == null) {
        if (!parameter.value.contains(Null)) {
          logger.fine('No matching argument for parameter ${parameter.key}');
          return const {};
        } else {
          parameterValues[parameter.key] = null;
        }
      }
    }
    logger.finer(parameterValues);
    if (parameterValues.isNotEmpty || parameters.isEmpty) {
      logger.fine('will execute with matched arguments from parameters');
      return parameterValues;
    }
    logger.warning('no matching arguments for the parameters');
    return const {};
  }

  final _exes = <ExecutableAndArguments>[];

  void addExe(String exe) {
    _exes.add(getExecutableAndArguments(exe));
  }

  void popExe() {
    _exes.removeLast();
  }

  Map<String, Object?>? _exeMethods;

  void addExeMethods(Map<String, Object?> exeMethods) {
    _exeMethods = exeMethods;
  }

  String _resolveExecutableInMethods(String executable) {
    final value = _exeMethods?[executable];
    if (value is String) {
      return value;
    }
    // TODO(predatorx7): parse methods
    return executable;
  }

  Future<ExecutableAndArguments> getResolvedExecutable() async {
    logger.config("script requested exes: ${_exes.join(', ')}");
    for (var i = _exes.length - 1; i >= 0; i--) {
      final exe = _exes[i];
      if (exe.executable.isEmpty) continue;
      final executable = await findExecutable(exe.executable);
      if (executable != null) {
        return (
          executable: _resolveExecutableInMethods(executable),
          arguments: exe.arguments,
        );
      }
    }

    const shellUserBinSh = '/usr/bin/sh';

    final fallbackShell = Platform.isWindows
        ? 'powershell.exe'
        : await findExecutable(shellUserBinSh) ?? '/bin/sh';

    final exesString = toStringForListOr(_exes.map((e) => e.executable));
    logger.warning(
      'Failed to find $exesString in PATH. Using $fallbackShell.',
    );

    return getExecutableAndArguments(fallbackShell);
  }

  Future<void> run(
    List<String> instructions,
  ) async {
    final executable = await getResolvedExecutable();
    logger.config('Running instructions using `$executable`');
    if (!await hasExecutionPermission(executable.executable)) {
      logger.severe(
        'Executable `$executable` does not have permission to run.',
      );
    }
    logger.fine({
      'executable': executable,
      'instructions': instructions,
    });
    await runProcess(
      executable,
      logger,
      instructions,
      io,
    );
  }

  FutureOr<bool> invokeFunction(
    ScriptFunctions function,
    Map<String, Object?> resolvedParameters,
  ) async {
    await run(
      function.instructions.map((e) {
        return interpolateValues(e, resolvedParameters.map((key, value) {
          return MapEntry(
            key,
            value?.toString() ?? '',
          );
        }));
      }).toList(),
    );
    return true;
  }
}
