// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegaleseSection _$LegaleseSectionFromJson(Map<String, dynamic> json) =>
    LegaleseSection(
      json['copyright'] as String?,
      json['license'] as String?,
    );

Map<String, dynamic> _$LegaleseSectionToJson(LegaleseSection instance) =>
    <String, dynamic>{
      'copyright': instance.copyright,
      'license': instance.license,
    };

AuthorSection _$AuthorSectionFromJson(Map<String, dynamic> json) =>
    AuthorSection(
      json['name'] as String?,
      json['email'] as String?,
    );

Map<String, dynamic> _$AuthorSectionToJson(AuthorSection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
    };

OptionsSection _$OptionsSectionFromJson(Map<String, dynamic> json) =>
    OptionsSection(
      isVerboseModeAvailable: json['verbose_mode_available'] as bool?,
      exe: json['exe'] as String?,
    );

Map<String, dynamic> _$OptionsSectionToJson(OptionsSection instance) =>
    <String, dynamic>{
      'verbose_mode_available': instance.isVerboseModeAvailable,
      'exe': instance.exe,
    };

AppMetadata _$AppMetadataFromJson(Map<String, dynamic> json) => AppMetadata(
      scriptrVersion: json['scriptr'] as String?,
      options: json['options'] == null
          ? null
          : OptionsSection.fromJson(json['options'] as Map<String, dynamic>),
      name: json['name'] as String?,
      version: json['version'] as String?,
      legalese: json['legalese'] == null
          ? null
          : LegaleseSection.fromJson(json['legalese'] as Map<String, dynamic>),
      author: json['author'] == null
          ? null
          : AuthorSection.fromJson(json['author'] as Map<String, dynamic>),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AppMetadataToJson(AppMetadata instance) =>
    <String, dynamic>{
      'scriptr': instance.scriptrVersion,
      'options': instance.options,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'legalese': instance.legalese,
      'author': instance.author,
    };
