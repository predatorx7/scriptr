import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:io/io.dart' as io;
import 'package:path/path.dart';
import 'package:scriptr/src/io/cli.dart';
import 'package:scriptr/src/logging.dart';

import 'arguments.dart';

List<String> getWindowsPathExtensions() {
  const windowsDefaultPathExt = <String>['.exe', '.bat', '.cmd', '.com'];
  const String windowsEnvPathSeparator = ';';

  return [
    ...windowsDefaultPathExt,
    ...?Platform.environment['PATHEXT']
        ?.split(windowsEnvPathSeparator)
        .map((ext) => ext.toLowerCase())
        .toList(growable: false)
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
        .map((ext) => ext.toLowerCase())
        .toList(growable: false)
  ];
}

List<String>? getPosixPath() {
  const String windowsEnvPathSeparator = ';';

  return [
    ...?Platform.environment['PATH']
        ?.split(windowsEnvPathSeparator)
        .map((ext) => ext.toLowerCase())
        .toList(growable: false)
  ];
}

List<String> getExecutableExtensions() {
  if (Platform.isWindows) return getWindowsPathExtensions();
  return getPosixExecutableExtensions();
}

FutureOr<String?> findExecutable(String exe) async {
  final exeBasename = basename(exe);
  if (exeBasename.isEmpty) return null;
  final fileExecutable = File(exe);
  if (fileExecutable.existsSync()) return fileExecutable.absolute.path;
  final executable = await findExecutableFromPath(exe);
  if (executable != null) return executable.path;
  return null;
}

List<String>? getEnvironmentPath() {
  if (Platform.isWindows) return getWindowsPath();
  return getPosixPath();
}

Future<bool> hasExecutionPermission(String executablePath) async {
  if (Platform.isWindows) {
    return true;
  }
  final executableFile = File(executablePath);
  final stats = await executableFile.stat();
  if (stats.type == FileSystemEntityType.file ||
      stats.type == FileSystemEntityType.link) {
    // Check executable permission
    if (stats.mode & 0x49 != 0) {
      // binary 001001001
      // executable
      return true;
    }
  }
  return false;
}

/// Find command in path
FutureOr<File?> findExecutableFromPath(String command) async {
  if (await File(command).exists()) {
    return File(command);
  }

  final paths = getEnvironmentPath();
  if (paths == null) return null;
  final extensions = getExecutableExtensions();
  final commandPath = absolute(canonicalize(command));
  final commandBasename = basename(commandPath);
  final commandBasenameWithoutExt = basenameWithoutExtension(commandPath);
  final possibleCommandNames = {
    commandBasenameWithoutExt,
    commandBasename,
    for (final ext in extensions) '$commandBasenameWithoutExt$ext',
  };
  for (final path in paths) {
    final pathDirectory = Directory(path);
    if (!await pathDirectory.exists()) continue;
    final maybeCommands = pathDirectory
        .listSync()
        .where((it) {
          return basenameWithoutExtension(it.path).toLowerCase() ==
              commandBasenameWithoutExt.toLowerCase();
        })
        .where((it) {
          final itPath = basename(it.path).toLowerCase();
          for (final possibleCommandName in possibleCommandNames) {
            if (possibleCommandName == itPath) return true;
          }
          return basenameWithoutExtension(itPath) ==
              commandBasenameWithoutExt.toLowerCase();
        })
        .where((it) => FileSystemEntity.isFileSync(it.path))
        .map((e) => File(e.absolute.path));

    return maybeCommands.firstOrNull;
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
