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
    bool? isVerboseModeAvailable,
    this.exe,
    this.exeMethods,
  }) : isVerboseModeAvailable = isVerboseModeAvailable ?? true;

  @JsonKey(name: 'verbose_mode_available')

  /// Is verbose mode available? Defaults to true.
  final bool? isVerboseModeAvailable;

  @JsonKey(name: 'exe')

  /// Default executable
  final String? exe;

  @JsonKey(name: 'exe_methods')

  /// Default executable
  final Map<String, Object?>? exeMethods;

  factory OptionsSection.fromJson(Map<String, Object?> json) =>
      _$OptionsSectionFromJson(json);

  factory OptionsSection.fromMetadataJson(Map<String, Object?>? json) {
    final options = json?['options'];
    if (options == null || options is! Map<String, dynamic>) {
      return const OptionsSection();
    }
    return OptionsSection.fromJson(options);
  }

  Map<String, Object?> toJson() => _$OptionsSectionToJson(this);
}

@JsonSerializable()
class AppMetadata {
  const AppMetadata({
    this.scriptrVersion,
    this.name,
    this.version,
    this.legalese,
    this.author,
    this.description,
  });

  @JsonKey(name: 'scriptr')
  final String? scriptrVersion;

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
