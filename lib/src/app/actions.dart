import '../utils/interpolations.dart';
import 'app.dart';
import 'dart:math' as math;

class ScriptAction {
  final ScriptApp app;

  const ScriptAction(this.app);

  String createGlobalHelpMessage() {
    final buffer = StringBuffer();
    final about = app.metadata;
    final aboutMap = about.toJson();
    final description = app.metadata.description;

    if (description != null && description.isNotEmpty) {
      buffer.writeln(interpolateValues(description.trim(), aboutMap));
      buffer.writeln();
    }

    final appExecutableName = app.metadata.name?.toLowerCase() ?? 'app';

    buffer.writeln(
      'Usage: $appExecutableName <command> [options]',
    );
    buffer.writeln();
    buffer.writeln('Available commands:');
    buffer.writeln();

    final commandEntries = app.commands.entries;
    final maxLengthOfName = commandEntries
        .map((e) => e.key.length)
        .reduce((value, element) => math.max(value, element));

    for (final command in commandEntries) {
      final commandName = command.key;
      final description =
          command.value.section?.info?.description?.trim() ?? '';
      buffer.writeln(
        '  ${commandName.padRight(maxLengthOfName)}  ${interpolateValues(description.trim(), aboutMap)}',
      );
    }

    buffer.writeln();
    buffer.writeln(
      'Run "$appExecutableName help <something>" to read about a specific subcommand or concept.',
    );

    return buffer.toString();
  }

  String noCommandsMatchedMessage() {
    final buffer = StringBuffer();
    final about = app.metadata;

    final appExecutableName = about.name?.toLowerCase() ?? 'app';

    buffer.writeln();
    buffer.writeln(
      '$appExecutableName: not a $appExecutableName command. See \'$appExecutableName help\'',
    );

    return buffer.toString();
  }
}
