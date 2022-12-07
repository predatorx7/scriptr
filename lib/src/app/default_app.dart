import 'dart:convert';

import '../script.dart';
import '../scriptr_utils.dart';
import 'app.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.data);

  @override
  void run() async {
    final scriptContent = await getScriptContent(data.arguments);
    final config = getScriptContentAsMap(scriptContent);

    final app = ScriptApp.fromJson(config);

    data.output.writeln(json.encode(app));
  }
}
