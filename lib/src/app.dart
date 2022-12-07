import 'dart:convert';

import 'app/app.dart';
import 'script.dart';

class DefaultSciptrApp extends ScriptRunner {
  DefaultSciptrApp(super.data);

  @override
  void run() {
    final app = ScriptApp.fromJson(data.config);

    data.output.writeln(json.encode(app));
    data.output.writeln(data.applicationArguments);
  }
}
