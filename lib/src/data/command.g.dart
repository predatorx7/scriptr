// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScriptCommandInformationSection _$ScriptCommandInformationSectionFromJson(
        Map<String, dynamic> json) =>
    ScriptCommandInformationSection(
      json['description'] as String?,
      json['is_named_enabled'] as bool?,
      json['is_named_abbreviation_enabled'] as bool?,
      json['is_positional_enabled'] as bool?,
      json['is_positional_abbreviation_enabled'] as bool?,
    );

Map<String, dynamic> _$ScriptCommandInformationSectionToJson(
        ScriptCommandInformationSection instance) =>
    <String, dynamic>{
      'description': instance.description,
      'is_named_enabled': instance.isNamedEnabled,
      'is_named_abbreviation_enabled': instance.isNamedAbbreviationEnabled,
      'is_positional_enabled': instance.isPositionalEnabled,
      'is_positional_abbreviation_enabled':
          instance.isPositionalAbbreviationEnabled,
    };

FlagDataSection _$FlagDataSectionFromJson(Map<String, dynamic> json) =>
    FlagDataSection(
      json['abbr'] as String,
      json['default'],
      json['description'] as String?,
    );

Map<String, dynamic> _$FlagDataSectionToJson(FlagDataSection instance) =>
    <String, dynamic>{
      'abbr': instance.abbreviation,
      'default': instance.defaultValue,
      'description': instance.description,
    };

ScriptCommandSection _$ScriptCommandSectionFromJson(
        Map<String, dynamic> json) =>
    ScriptCommandSection(
      alias:
          (json['alias'] as List<dynamic>?)?.map((e) => e as String).toList(),
      info: json['info'] == null
          ? null
          : ScriptCommandInformationSection.fromJson(
              json['info'] as Map<String, dynamic>),
      flags: (json['flags'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, FlagDataSection.fromJson(e as Map<String, dynamic>)),
      ),
      exe: json['exe'] as String?,
    );

Map<String, dynamic> _$ScriptCommandSectionToJson(
        ScriptCommandSection instance) =>
    <String, dynamic>{
      'alias': instance.alias,
      'info': instance.info,
      'flags': instance.flags,
      'exe': instance.exe,
    };
