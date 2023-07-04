import 'dart:io' as io;

class CliIO {
  final io.Stdin? _stdin;
  final io.Stdout? _stdout;
  final io.Stdout? _stderr;

  CliIO({
    io.Stdin? stdin,
    io.Stdout? stdout,
    io.Stdout? stderr,
  })  : _stdin = stdin,
        _stdout = stdout,
        _stderr = stderr;

  final io.IOOverrides? _overrides = io.IOOverrides.current;

  io.Stdin get stdin => _stdin ?? _overrides?.stdin ?? io.stdin;
  io.Stdout get stdout => _stdout ?? _overrides?.stdout ?? io.stdout;
  io.Stdout get stderr => _stderr ?? _overrides?.stderr ?? io.stderr;

  /// Read input via [stdin.readLineSync].
  String? readln() => stdin.readLineSync();

  /// Write message via [stdout.write].
  void write(String? message) => stdout.write(message);

  /// Write message via [stdout.writeln].
  void writeln(String? message) => stdout.writeln(message);

  /// Write message via [stderr.write].
  void writeError(String? message) => stderr.write(message);

  /// Write message via [stderr.writeln].
  void writelnError(String? message) => stderr.writeln(message);
}
