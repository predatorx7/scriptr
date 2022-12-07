import 'dart:convert';

import 'app/app.dart';
import 'script.dart';
import 'scriptr_utils.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.data);

  @override
  void run() async {
    final scriptContent = await getScriptContent(data.applicationArguments);
    final config = getScriptContentAsMap(scriptContent);

    final app = ScriptApp.fromJson(config);

    data.output.writeln(json.encode(app));
    data.output.writeln(data.applicationArguments);
  }
}
