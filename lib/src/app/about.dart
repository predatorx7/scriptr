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
class AboutSection {
  const AboutSection({
    this.scriptrVersion,
    this.exe,
    this.name,
    this.version,
    this.legalese,
    this.author,
    this.description,
  });

  @JsonKey(name: 'scriptr')
  final String? scriptrVersion;

  @JsonKey(name: 'exe')
  final String? exe;

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

  factory AboutSection.fromJson(Map<String, Object?> json) =>
      _$AboutSectionFromJson(json);

  Map<String, Object?> toJson() => _$AboutSectionToJson(this);
}
