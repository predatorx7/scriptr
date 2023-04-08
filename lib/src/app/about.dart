import 'package:json_annotation/json_annotation.dart';

part 'about.g.dart';

@JsonSerializable()
class LegaleseSection {
  @JsonKey(name: 'copyright')
  final String? copyright;

  @JsonKey(name: 'license')
  final String? license;

  const LegaleseSection(
    this.copyright,
    this.license,
  );

  factory LegaleseSection.fromJson(Map<String, Object?> json) =>
      _$LegaleseSectionFromJson(json);

  Map<String, Object?> toJson() => _$LegaleseSectionToJson(this);
}

@JsonSerializable()
class AuthorSection {
  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'email')
  final String? email;

  const AuthorSection(this.name, this.email);

  factory AuthorSection.fromJson(Map<String, Object?> json) =>
      _$AuthorSectionFromJson(json);

  Map<String, Object?> toJson() => _$AuthorSectionToJson(this);
}

@JsonSerializable()
class OptionsSection {
  const OptionsSection({
    this.isVerboseModeAvailable,
    this.exe,
  });

  @JsonKey(name: 'verbose_mode_available')
  final bool? isVerboseModeAvailable;

  @JsonKey(name: 'exe')
  final String? exe;

  factory OptionsSection.fromJson(Map<String, Object?> json) =>
      _$OptionsSectionFromJson(json);

  Map<String, Object?> toJson() => _$OptionsSectionToJson(this);
}

@JsonSerializable()
class AppMetadata {
  const AppMetadata({
    this.scriptrVersion,
    this.options,
    this.name,
    this.version,
    this.legalese,
    this.author,
    this.description,
  });

  @JsonKey(name: 'scriptr')
  final String? scriptrVersion;

  @JsonKey(name: 'options')
  final OptionsSection? options;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'version')
  final String? version;

  @JsonKey(name: 'legalese')
  final LegaleseSection? legalese;

  @JsonKey(name: 'author')
  final AuthorSection? author;

  factory AppMetadata.fromJson(Map<String, Object?> json) =>
      _$AppMetadataFromJson(json);

  Map<String, Object?> toJson() => _$AppMetadataToJson(this);
}
