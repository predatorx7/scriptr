import 'dart:async';
import 'dart:io';

import 'app.dart';
import 'logging.dart';
import 'scriptr_utils.dart';

class ScriptData {
  final Map<String, Object?> config;
  final List<String> applicationArguments;
  final IOSink output;
  final IOSink errorOutput;

  const ScriptData(
    this.config,
    this.applicationArguments,
    this.output,
    this.errorOutput,
  );
}

typedef ScriptRunnerCreateCallback = ScriptRunner Function(ScriptData data);

abstract class ScriptRunner {
  final ScriptData data;

  const ScriptRunner(
    this.data,
  );

  void run();
}

Future<void> runApp(
  List<String> args, {
  ScriptRunnerCreateCallback build = DefaultSciptrApp.new,
  IOSink? output,
  IOSink? errorOutput,
}) async {
  setupLogger(args);

  final scriptContent = await getScriptContent(args);
  final config = getScriptContentAsMap(scriptContent);

  final applicationArguments = args.length > 1 ? args.sublist(1) : <String>[];

  final appData = ScriptData(
    config,
    applicationArguments,
    output ?? stdout,
    errorOutput ?? stderr,
  );

  final runner = build(appData);

  runner.run();
}
