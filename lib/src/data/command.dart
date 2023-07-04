import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:scriptr/src/errors.dart';

import 'entries.dart';

part 'command.g.dart';

const _typeByNames = {
  'string': String,
  'datetime': DateTime,
  'num': num,
  'int': int,
  'double': double,
  'bool': bool,
  '?': Null,
};

Object resolveValueForTypes(String value, List<Type> types) {
  for (final type in types) {
    switch (type) {
      case String:
        return value;
      case DateTime:
        return DateTime.parse(value);
      case num:
        return num.parse(value);
      case int:
        return num.parse(value);
      case double:
        return num.parse(value);
      case bool:
        final v = value.toLowerCase().trim();
        return v == 'true' || v != '0' || v == 'y';
      default:
    }
  }
  throw ScriptrError(
    'Failed to parse value "$value" as a type from $types',
  );
}

class ScriptFunctions {
  const ScriptFunctions(
    this.signature,
    this.instructions,
  );

  final String signature;
  final List<String> instructions;

  Map<String, List<Type>> get parameters {
    final parameterStart = signature.indexOf('(');
    final parameterEnd = signature.indexOf(')');
    final Map<String, List<Type>> parameters = {};
    if (parameterStart != -1 && parameterEnd != -1) {
      final parametersString = signature.substring(
        parameterStart + 1,
        parameterEnd,
      );
      final parametersList =
          parametersString.replaceAll(RegExp(r'\s\b|\b\s'), '').split(',');
      for (final parameter in parametersList) {
        final parameterItems = parameter.split(':');
        if (parameterItems.isEmpty) {
          throw ScriptrError('Invalid parameter in signature: "$signature"');
        }
        final variableName = parameterItems.first;
        final types = <Type>[];
        parameters[variableName] = types;
        final argument = parameterItems[1].toLowerCase();
        for (final type in _typeByNames.entries) {
          if (argument.contains(type.key)) {
            types.add(type.value);
          }
        }
      }
    }
    return parameters;
  }
}

@JsonSerializable()
class ScriptCommandInformationSection {
  const ScriptCommandInformationSection(
    this.description,
    this.isNamedEnabled,
    this.isNamedAbbreviationEnabled,
    this.isPositionalEnabled,
    this.isPositionalAbbreviationEnabled,
  );

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'is_named_enabled')
  final bool? isNamedEnabled;

  @JsonKey(name: 'is_named_abbreviation_enabled')
  final bool? isNamedAbbreviationEnabled;

  @JsonKey(name: 'is_positional_enabled')
  final bool? isPositionalEnabled;

  @JsonKey(name: 'is_positional_abbreviation_enabled')
  final bool? isPositionalAbbreviationEnabled;

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
