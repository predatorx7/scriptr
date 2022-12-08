import 'package:scriptr/src/scriptr_args.dart';

import '../script.dart';
import '../scriptr_utils.dart';
import 'actions.dart';
import 'app.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.data);

  @override
  void run() async {
    final scriptContent = await getScriptContent(data.arguments);
    final config = getScriptContentAsMap(scriptContent);

    final app = ScriptApp.fromJson(config);

    final arguments = Argument.parseApplicationArguments(data.arguments);

    late final helpMessage = ScriptAction().createGlobalHelpMessage(app);

    if (arguments.isEmpty) {
      data.output.write(helpMessage);
      return;
    }

    for (final argument in arguments) {
      data.output.writeln(argument.toJson());
    }

    data.output.write(ScriptAction().noCommandsMatchedMessage(app));
  }
}
