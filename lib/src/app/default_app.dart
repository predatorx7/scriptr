import 'package:scriptr/src/scriptr_args.dart';
import 'package:scriptr/src/scriptr_params.dart';

import '../script.dart';
import '../scriptr_utils.dart';
import 'actions.dart';
import 'app.dart';

class DefaultSciptrApp extends Scriptr {
  DefaultSciptrApp(super.context);

  @override
  void run() async {
    final scriptContent = await getScriptContent(context.arguments);
    final config = getScriptContentAsMap(scriptContent);

    final app = ScriptApp.fromJson(config);

    final arguments = Argument.parseApplicationArguments(context.arguments);
    final isVerbose = arguments.containsNamedParameter(
      Parameter.named('verbose', 'v'),
    );

    context.setVerboseMode(isVerbose);

    final scriptAction = ScriptAction(app);

    late final helpMessage = scriptAction.createGlobalHelpMessage();

    if (arguments.isEmpty) {
      context.logger.info(helpMessage);
      return;
    }

    for (final argument in arguments) {
      context.logger.fine(argument.toJson());
    }

    context.logger.info(scriptAction.noCommandsMatchedMessage());
  }
}
