import 'dart:io';

import 'package:logging/logging.dart';
import 'package:process_run/shell.dart';
import 'package:scriptr/src/app/command.dart';

import '../scriptr_args.dart';
import '../utils/interpolations.dart';
import 'app.dart';
import 'dart:math' as math;
import 'package:process_run/which.dart';

class ScriptAction {
  final ScriptApp app;
  final Logger logger;

  ScriptAction(this.app, this.logger) {
    final exe = app.metadata.options?.exe;
    if (exe != null) {
      addExe(exe);
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
        final args = arguments.length > 1
            ? arguments.toList().sublist(1)
            : const <Argument>[];
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
    } else {
      final seeText = 'See \'$parentFullCommandName help\'.';
      buffer.writeln(
        '$appExecutableName: not a $appExecutableName command. $seeText',
      );
    }
    return buffer.toString();
  }

  Map<String, Object?>? resolveParameters(
    Map<String, List<Type>> parameters,
    Arguments arguments,
    Argument commandArgument,
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
          return null;
        } else {
          parameterValues[parameter.key] = null;
        }
      }
    }
    logger.finer(parameterValues);
    if (parameterValues.isNotEmpty || parameters.isEmpty) {
      logger.info('will execute with matched arguments from parameters');
      return parameterValues;
    }
    logger.info('no matching arguments for the parameters');
    return null;
  }

  final _exes = <String>[];

  void addExe(String exe) {
    _exes.add(exe);
  }

  void popExe() {
    _exes.removeLast();
  }

  String getResolvedExecutable() {
    for (var i = _exes.length - 1; i >= 0; i--) {
      final exe = _exes[i];
      if (exe.isEmpty) continue;
      final executable = whichSync(exe);
      if (executable != null && executable.isNotEmpty) return executable;
      final fileExecutable = File(exe);
      if (fileExecutable.existsSync()) return fileExecutable.absolute.path;
    }
    return Platform.isWindows ? 'pwsh' : '/usr/bin/sh';
  }

  Future<void> run(List<String> instructions,  List<String> arguments) async {
    final executable = getResolvedExecutable();
    final shell = Shell();

    await shell.runExecutableArguments(executable, arguments, onProcess: (process) {
      process.stdin.writeAll(instructions, '\n');
    });
  }
}
