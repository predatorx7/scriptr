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

AboutSection _$AboutSectionFromJson(Map<String, dynamic> json) => AboutSection(
      scriptrVersion: json['scriptr'] as String?,
      exe: json['exe'] as String?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      legalese: json['legalese'] == null
          ? null
          : LegaleseSection.fromJson(json['legalese'] as Map<String, dynamic>),
      author: json['author'] == null
          ? null
          : AuthorSection.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AboutSectionToJson(AboutSection instance) =>
    <String, dynamic>{
      'scriptr': instance.scriptrVersion,
      'exe': instance.exe,
      'name': instance.name,
      'version': instance.version,
      'legalese': instance.legalese,
      'author': instance.author,
    };
