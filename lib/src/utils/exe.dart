import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:io/io.dart' as io;
import 'package:path/path.dart';
import 'package:scriptr/src/io/cli.dart';
import 'package:scriptr/src/logging.dart';
import 'package:scriptr/src/utils/config_file.dart';

import 'arguments.dart';

List<String> getWindowsPathExtensions() {
  const windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];
  const String windowsEnvPathSeparator = ';';

  return [
    ...windowsDefaultPathExt,
    ...?Platform.environment['PATHEXT']
        ?.split(windowsEnvPathSeparator)
        .map((ext) => ext.toLowerCase()),
  ];
}

List<String> getPosixExecutableExtensions() {
  const posixDefaultPathExt = <String>['', '.exe', '.sh', '.appimage'];

  return posixDefaultPathExt;
}

List<String>? getWindowsPath() {
  const String windowsEnvPathSeparator = ';';

  return [
    ...?Platform.environment['PATH']
        ?.split(windowsEnvPathSeparator)
        .map((ext) => ext.toLowerCase()),
  ];
}

List<String>? getPosixPath() {
  const String unixEnvPathSeparator = ':';

  return [
    ...?Platform.environment['PATH']
        ?.split(unixEnvPathSeparator)
        .map((ext) => ext.toLowerCase()),
  ];
}

List<String> getExecutableExtensions() {
  if (Platform.isWindows) return getWindowsPathExtensions();
  return getPosixExecutableExtensions();
}

FutureOr<String?> findExecutable(String exe) async {
  final log = logger('findExecutable').finest;
  final exeBasename = basename(exe);
  log('basename of "$exe" == $exeBasename');
  if (exeBasename.isEmpty) return null;
  final fileExecutable = File(exe);
  if (await fileExecutable.exists()) return fileExecutable.absolute.path;
  final executable = await findExecutableFromPath(exe);
  log('Executable $exe in path $executable');
  if (executable != null) return executable.path;
  return null;
}

List<String>? getEnvironmentPath() {
  if (Platform.isWindows) return getWindowsPath();
  return getPosixPath();
}

/// Find command in path
FutureOr<File?> findExecutableFromPath(String command) async {
  final log = logger('findExecutableFromPath').finest;
  if (await File(command).exists()) {
    return File(command);
  }

  final paths = getEnvironmentPath();
  log('paths length: ${paths?.length}');
  if (paths == null) return null;
  final extensions = getExecutableExtensions();
  final commandPath = absolute(canonicalize(command));
  final commandBasename = basename(commandPath);
  final commandBasenameWithoutExt = basenameWithoutExtension(commandPath);
  final possibleCommandNames = [
    commandPath,
    commandBasename,
    commandBasenameWithoutExt,
    for (final ext in extensions) '$commandBasenameWithoutExt$ext',
  ];
  log('possible command names: ${possibleCommandNames.join(", ")}');
  for (final path in paths) {
    final pathDirectory = Directory(path);
    if (!await pathDirectory.exists()) continue;

    for (final i in possibleCommandNames) {
      final fullName = File(join(path, i));
      if (await fullName.exists()) return fullName.absolute;
    }
    final maybeCommands = pathDirectory
        .listSync()
        .where((it) => FileSystemEntity.isFileSync(it.path))
        .where((it) {
      return basenameWithoutExtension(it.path).toLowerCase() ==
          commandBasenameWithoutExt.toLowerCase();
    }).where((it) {
      final itPath = basename(it.path).toLowerCase();
      for (final possibleCommandName in possibleCommandNames) {
        if (possibleCommandName == itPath) return true;
      }
      return basenameWithoutExtension(itPath) ==
          commandBasenameWithoutExt.toLowerCase();
    }).map((e) => File(e.absolute.path));

    final cmd = maybeCommands.firstOrNull;
    if (cmd == null) continue;
    return cmd;
  }

  return null;
}

Future<void> runProcess(
  ExecutableAndArguments executable,
  Logger logger,
  List<String> instructions,
  CliIO cliIO,
) async {
  final debugInstruction =
      '${executable.executable} ${executable.arguments}\n\n${instructions.join("\n")}';
  final log = logger('runProcess');
  log.fine(debugInstruction);
  try {
    final pm = io.ProcessManager(
      stdin: cliIO.stdin,
      stdout: cliIO.stdout,
      stderr: cliIO.stderr,
    );

    final process = await pm.spawn(
      executable.executable,
      executable.arguments,
      runInShell: true,
    );

    final exe = executable.executable;
    if (instructions.lastOrNull?.contains('exit') != true) {
      if (exe.contains('python')) {
        instructions.add('exit()');
      } else if (exe == '/bin/sh' ||
          exe == '/usr/bin/sh' ||
          exe.contains('bash') ||
          exe.contains('zsh') ||
          exe.contains('pwsh') ||
          exe.contains('powershell') ||
          exe.contains('cmd')) {
        instructions.add('exit');
      } else {
        log.fine(
          'Could not exit automatically, unknown environment. Processes ran from unknown environments should exit on their own.',
        );
      }
    }

    for (final instruction in instructions) {
      log.finest(
        'Writing instruction to process stdin $instruction',
      );
      process.stdin.writeln(instruction);
    }

    final exitCode = await process.exitCode;
    exit(exitCode);
  } catch (e, s) {
    logger.severe('Failed to run process `$debugInstruction`', e, s);
  }
}
