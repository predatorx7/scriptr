import 'package:equatable/equatable.dart';

abstract class Parameter with EquatableMixin {
  const Parameter(this.name);

  final String name;

  const factory Parameter.positional(String name) = PositionalParameter;
  const factory Parameter.named(
    String name,
    String? abbreviation,
  ) = NamedParameter;

  @override
  List<Object?> get props => [name];

  bool get isPositional;
  bool get isNamed;
}

class PositionalParameter extends Parameter {
  const PositionalParameter(super.name);

  @override
  bool get isPositional => true;
  @override
  bool get isNamed => false;
}

class NamedParameter extends Parameter {
  final String? abbreviation;

  const NamedParameter(super.name, this.abbreviation);

  @override
  bool get isPositional => false;
  @override
  bool get isNamed => true;
}
