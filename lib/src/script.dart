import 'dart:async';
import 'dart:io';

import 'app.dart';
import 'logging.dart';

class ApplicationData {
  final List<String> applicationArguments;
  final IOSink output;
  final IOSink errorOutput;

  const ApplicationData(
    this.applicationArguments,
    this.output,
    this.errorOutput,
  );
}

typedef ScriptRunnerAppCreateCallback = Scriptr Function(ApplicationData data);

abstract class Scriptr {
  final ApplicationData data;

  const Scriptr(
    this.data,
  );

  void run();
}

Future<void> runApp(
  List<String> args, {
  ScriptRunnerAppCreateCallback build = DefaultSciptrApp.new,
  IOSink? output,
  IOSink? errorOutput,
}) async {
  setupLogger(args);

  final applicationArguments = args.length > 1 ? args.sublist(1) : <String>[];

  final appData = ApplicationData(
    applicationArguments,
    output ?? stdout,
    errorOutput ?? stderr,
  );

  final runner = build(appData);

  runner.run();
}
