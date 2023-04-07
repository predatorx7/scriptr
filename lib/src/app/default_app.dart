import 'package:logging/logging.dart';
import 'package:scriptr/src/scriptr_args.dart';
import 'package:scriptr/src/scriptr_params.dart';

import '../script.dart';
import '../scriptr_utils.dart';
import 'actions.dart';
import 'app.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.context);

  void setVerboseMode(bool isVerboseMode) {
    if (isVerboseMode) {
      context.logger.level = Level.ALL;
    } else {
      context.logger.level = Level.INFO;
    }
  }

  @override
  void run() async {
    final scriptContent = await getScriptContent(context.arguments);
    final config = getScriptContentAsMap(scriptContent);

    final arguments = Argument.parseApplicationArguments(context.arguments);
    final isVerbose = arguments.containsNamedParameter(
      Parameter.named('verbose', 'v'),
    );

    setVerboseMode(isVerbose);

    final app = ScriptApp.fromJson(config);
    final scriptAction = ScriptAction(app);

    late final helpMessage = scriptAction.createGlobalHelpMessage();

    if (arguments.isEmpty) {
      context.logger.info(helpMessage);
      return;
    }

    context.logger.fine(arguments);

    context.logger.info(scriptAction.noCommandsMatchedMessage());
  }
}
