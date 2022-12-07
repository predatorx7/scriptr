import 'package:pub_semver/pub_semver.dart';
import 'package:scriptr/src/logging.dart';

import 'about.dart';
import 'command.dart';
import 'entries.dart';

typedef ScriptAppJsonFactory = ScriptApp Function(Map<String, Object?> json);

class ScriptApp {
  final AboutSection about;
  final Map<String, ScriptCommand> commands;

  const ScriptApp(
    this.about,
    this.commands,
  );

  factory ScriptApp.fromJson(Map<String, Object?> json) {
    final scriptrVersion = (json['scriptr'] ?? '^1.0.0').toString();
    logging.config('Parsing version: $scriptrVersion');
    final version = VersionConstraint.parse(scriptrVersion);

    final factoryVersions = versionedFromJson.keys.toList()..sort();

    final effectiveVersion =
        factoryVersions.firstWhere(version.allows, orElse: () {
      throw UnsupportedError('Unsupported scriptr version: $scriptrVersion');
    });

    return versionedFromJson[effectiveVersion]!(json);
  }

  static final versionedFromJson = <Version, ScriptAppJsonFactory>{
    Version(1, 0, 0): (Map<String, Object?> json) {
      logging.info('parsing: ${json.keys.join(", ")}');
      final rootCommandsJson = withoutReservedEntries(
        json['commands'] as Map<String, Object?>?,
      );

      final commandEntries = rootCommandsJson.entries.map(
        (e) => MapEntry(
          e.key,
          ScriptCommand.fromJson(
            e.key,
            e.value as Map<String, Object?>,
          ),
        ),
      );

      return ScriptApp(
        AboutSection.fromJson(json),
        Map.fromEntries(commandEntries),
      );
    },
  };

  Map<String, Object?> toJson() {
    return {
      ...about.toJson(),
      'commands': commands,
    };
  }
}
