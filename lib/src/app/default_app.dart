import 'dart:convert';

import 'package:scriptr/src/scriptr_args.dart';

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

    final arguments = Argument.parseApplicationArguments(data.arguments);

    print(json.encode(arguments.toList()));
  }
}
