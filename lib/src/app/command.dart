import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'entries.dart';

part 'command.g.dart';

class ScriptFunctions {
  const ScriptFunctions(
    this.signature,
    this.instructions,
  );

  final String signature;
  final List<String> instructions;
}

@JsonSerializable()
class ScriptCommandInformationSection {
  const ScriptCommandInformationSection(
    this.description,
  );

  @JsonKey(name: 'description')
  final String? description;

  factory ScriptCommandInformationSection.fromJson(Map<String, Object?> json) =>
      _$ScriptCommandInformationSectionFromJson(json);

  Map<String, Object?> toJson() =>
      _$ScriptCommandInformationSectionToJson(this);
}

@JsonSerializable()
class FlagDataSection {
  const FlagDataSection(
    this.abbreviation,
    this.defaultValue,
    this.description,
  );

  @JsonKey(name: 'abbr')
  final String abbreviation;

  @JsonKey(name: 'default')
  final Object? defaultValue;

  @JsonKey(name: 'description')
  final String? description;

  factory FlagDataSection.fromJson(Map<String, Object?> json) =>
      _$FlagDataSectionFromJson(json);

  Map<String, Object?> toJson() => _$FlagDataSectionToJson(this);
}

@JsonSerializable()
class ScriptCommandSection {
  const ScriptCommandSection({
    this.alias,
    this.info,
    this.flags,
    this.exe,
  });

  @JsonKey(name: 'alias')
  final List<String>? alias;

  @JsonKey(name: 'info')
  final ScriptCommandInformationSection? info;

  @JsonKey(name: 'flags')
  final Map<String, FlagDataSection>? flags;

  @JsonKey(name: 'exe')
  final String? exe;

  factory ScriptCommandSection.fromJson(Map<String, Object?> json) =>
      _$ScriptCommandSectionFromJson(json);

  Map<String, Object?> toJson() => _$ScriptCommandSectionToJson(this);
}

class ScriptCommand {
  const ScriptCommand(
    this.name,
    this.section,
    this.subCommands,
    this.functions,
  );

  final String name;
  final ScriptCommandSection? section;
  final List<ScriptCommand>? subCommands;
  final List<ScriptFunctions>? functions;

  factory ScriptCommand.fromJson(String name, Map<String, Object?>? json) {
    ScriptCommandSection? section;
    List<ScriptCommand>? subCommands;
    List<ScriptFunctions>? functions;

    if (json != null) {
      section = ScriptCommandSection.fromJson(json);

      final data = withoutReservedEntries(
        json["commands"] as Map<String, Object?>?,
      );

      subCommands = data.entries.map(
        (e) {
          try {
            return ScriptCommand.fromJson(
              e.key,
              e.value as Map<String, Object?>?,
            );
          } catch (error) {
            throw Exception('Error parsing command: ${e.key}');
          }
        },
      ).toList();

      final functionEntries = getFunctionEntries(json);

      functions = functionEntries.entries.map((e) {
        return ScriptFunctions(e.key, instructionsFrom(e.value));
      }).toList();
    }

    return ScriptCommand(
      name,
      section,
      subCommands,
      functions,
    );
  }

  static List<String> instructionsFrom(Object? value) {
    if (value is List) return value.cast<String>();
    if (value is String) return LineSplitter.split(value).toList();
    return <String>[];
  }

  Map<String, Object?> toJson() {
    return {
      ...?section?.toJson(),
      if (functions != null)
        for (final f in functions!) f.signature: f.instructions,
    };
  }
}
