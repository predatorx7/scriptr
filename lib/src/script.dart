import 'dart:async';
import 'dart:io';

import 'app/default_app.dart';
import 'logging.dart';

class ApplicationData {
  final List<String> arguments;
  final IOSink output;
  final IOSink errorOutput;

  const ApplicationData(
    this.arguments,
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

  final appData = ApplicationData(
    args,
    output ?? stdout,
    errorOutput ?? stderr,
  );

  final runner = build(appData);

  runner.run();
}
