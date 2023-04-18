import 'package:equatable/equatable.dart';

import 'scriptr_params.dart';
import 'scriptr_utils.dart';

typedef Arguments = Iterable<Argument>;

extension ArgumentsExtension on Arguments {
  bool containsNamedArgument(String name) {
    for (final arg in this) {
      if (arg is! NamedArgument || (!arg.isNamed || arg.isAbbreviatedNamed)) {
        continue;
      }
      if (arg.name == name) return true;
    }
    return false;
  }

  NamedArgument? getFirstNamedArgument(String name) {
    for (final arg in this) {
      if (arg is! NamedArgument || (!arg.isNamed || arg.isAbbreviatedNamed)) {
        continue;
      }
      if (arg.name == name) return arg;
    }
    return null;
  }

  Iterable<NamedArgument> getAllNamedArgument(String name) sync* {
    for (final arg in this) {
      if (arg is! NamedArgument || (!arg.isNamed || arg.isAbbreviatedNamed)) {
        continue;
      }
      if (arg.name == name) yield arg;
    }
  }

  bool containsNamedAbbreviatedArgument(String name) {
    for (final arg in this) {
      if (arg is! NamedAbbreviatedArgument) {
        continue;
      }
      if (arg.name == name) return true;
    }
    return false;
  }

  NamedAbbreviatedArgument? getFirstNamedAbbreviatedArgument(String name) {
    for (final arg in this) {
      if (arg is! NamedAbbreviatedArgument) {
        continue;
      }
      if (arg.name == name) return arg;
    }
    return null;
  }

  Iterable<NamedAbbreviatedArgument> getAllNamedAbbreviatedArgument(
    String name,
  ) sync* {
    for (final arg in this) {
      if (arg is! NamedAbbreviatedArgument) {
        continue;
      }
      if (arg.name == name) yield arg;
    }
  }

  bool containsNamedParameter(Parameter parameter) {
    if (parameter is NamedParameter) {
      final abbreviation = parameter.abbreviation;
      if (abbreviation != null) {
        final hasParameter = containsNamedAbbreviatedArgument(abbreviation);
        if (hasParameter) return true;
      }
      return containsNamedArgument(parameter.name);
    }
    return false;
  }

  NamedArgument? getFirstNamedParameter(Parameter parameter) {
    if (parameter is NamedParameter) {
      final abbreviation = parameter.abbreviation;
      if (abbreviation != null) {
        final arg = getFirstNamedAbbreviatedArgument(abbreviation);
        if (arg != null) return arg;
      }
      return getFirstNamedArgument(parameter.name);
    }
    return null;
  }

  Iterable<NamedArgument> getAllNamedParameter(Parameter parameter) sync* {
    if (parameter is NamedParameter) {
      final abbreviation = parameter.abbreviation;
      if (abbreviation != null) {
        final args = getAllNamedAbbreviatedArgument(abbreviation);
        yield* args;
      }
      yield* getAllNamedArgument(parameter.name);
    }
  }

  String toSpaceSeparatedString() {
    final preArg = where((e) => e is! NamedAbbreviatedArgument).map((e) {
      return e.toRawString();
    }).join(' ');
    final namedArgs = whereType<NamedAbbreviatedArgument>();
    if (namedArgs.isEmpty) return preArg;
    final postArg = namedArgs.toRawString();
    return '$preArg $postArg';
  }
}

abstract class Argument with EquatableMixin {
  const Argument();

  static Arguments parseApplicationArguments(List<String> arguments) {
    final usedConfigFromArguments =
        arguments.isNotEmpty && hasValidConfigFileExtension(arguments.first);
    final applicationArguments =
        usedConfigFromArguments ? arguments.sublist(1) : arguments;

    return Argument.fromArguments(applicationArguments);
  }

  static Arguments fromArguments(List<String> arguments) sync* {
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final isNamedArgument = arg.startsWith('-');
      final subArgs = arguments.sublist(i + 1);
      if (isNamedArgument) {
        final isLongNamedArgument = arg.startsWith('--');
        if (isLongNamedArgument) {
          yield NamedArgument.fromArguments(
            arg,
            subArgs,
          );
        } else {
          final params = NamedAbbreviatedArgument.fromArguments(
            arg,
            subArgs,
          );
          for (final p in params) {
            yield p;
          }
        }
      } else {
        yield PositionalArgument.fromArguments(arg, subArgs);
      }
    }
  }

  Map<String, Object> toJson();

  bool get isPosition;
  bool get isNamed;
  bool get isAbbreviatedNamed;

  String toRawString();

  const factory Argument.positional(
    String value,
    Iterable<Argument> subArgs,
  ) = PositionalArgument;

  const factory Argument.parameterAbbreviatedNamed(
    String name,
    Iterable<PositionalArgument> arguments,
    Iterable<NamedAbbreviatedArgument> options,
  ) = NamedArgument.abbreviated;

  const factory Argument.parameterNamed(
    String name,
    Iterable<PositionalArgument> arguments,
    Iterable<NamedAbbreviatedArgument> options,
  ) = NamedArgument;
}

class PositionalArgument extends Argument {
  final String value;
  final Iterable<Argument> subArgs;

  const PositionalArgument(
    this.value,
    this.subArgs,
  );

  factory PositionalArgument.fromArguments(String value, List<String> subArgs) {
    return PositionalArgument(value, Argument.fromArguments(subArgs));
  }

  @override
  Map<String, Object> toJson() {
    return {
      'PositionalArgument': {
        'value': value,
        'subArgs': subArgs.map((e) => e.toJson()).toList(),
      }
    };
  }

  @override
  String toString() {
    return 'PositionalArgument(value: $value, subArgs: $subArgs)';
  }

  @override
  List<Object?> get props => [
        value,
        subArgs,
      ];

  @override
  bool get isPosition => true;

  @override
  bool get isNamed => false;

  @override
  bool get isAbbreviatedNamed => false;

  @override
  String toRawString() {
    return value;
  }
}

class NamedArgument extends Argument {
  final String name;
  final Iterable<PositionalArgument> arguments;
  final Iterable<NamedAbbreviatedArgument> options;

  const NamedArgument(
    this.name,
    this.arguments,
    this.options,
  );

  factory NamedArgument.fromArguments(
    String name,
    List<String> arguments,
  ) {
    return NamedArgument(
      NamedArgument.resolveName(name),
      NamedArgument.resolvePositionalArguments(arguments),
      NamedArgument.resolveParameterArguments(arguments),
    );
  }

  const factory NamedArgument.abbreviated(
    String name,
    Iterable<PositionalArgument> arguments,
    Iterable<NamedAbbreviatedArgument> options,
  ) = NamedAbbreviatedArgument;

  @override
  Map<String, Object> toJson() {
    return {
      'NamedParameter': {
        'name': name,
        'arguments': arguments.map((e) => e.toJson()).toList(),
        'options': options.map((e) => e.toJson()).toList(),
      }
    };
  }

  @override
  String toString() {
    return 'NamedParameter(name: $name, arguments: $arguments, options: $options)';
  }

  @override
  List<Object?> get props => [
        name,
        arguments,
        options,
      ];

  @override
  bool get isPosition => false;

  @override
  bool get isNamed => true;

  @override
  bool get isAbbreviatedNamed => false;

  static String resolveName(String name) {
    if (!name.startsWith('--')) {
      throw ArgumentError.value(
        name,
        'option',
        'Option\'s name must start with "--"',
      );
    }
    var n = name.substring(2);
    if (n.isEmpty) {
      throw ArgumentError.value(
        name,
        'option',
        'Option\'s name must not be empty',
      );
    }
    return n;
  }

  static Iterable<PositionalArgument> resolvePositionalArguments(
    List<String> arguments,
  ) sync* {
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final isParameter = arg.startsWith('-');
      if (!isParameter) {
        final subArgs = arguments.sublist(i + 1);
        yield PositionalArgument.fromArguments(arg, subArgs);
        continue;
      }
      final isFullParameter = arg.startsWith('--');
      if (isFullParameter) {
        break;
      }
    }
  }

  static Iterable<NamedAbbreviatedArgument> resolveParameterArguments(
    List<String> arguments,
  ) sync* {
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final isParameter = arg.startsWith('-');
      if (isParameter) {
        final anps = NamedAbbreviatedArgument.fromArguments(
          arg,
          arguments.sublist(i + 1),
        );
        for (final a in anps) {
          yield a;
        }
        continue;
      }
      final isFullParameter = arg.startsWith('--');
      if (isFullParameter) {
        break;
      }
    }
  }

  @override
  String toRawString() {
    return '--$name';
  }
}

extension NamedAbbreviatedArgumentExtension
    on Iterable<NamedAbbreviatedArgument> {
  String toRawString() {
    if (isEmpty) return '';
    final allFlagNames = map((e) => e.name).join();
    return '-$allFlagNames';
  }
}

class NamedAbbreviatedArgument extends NamedArgument {
  const NamedAbbreviatedArgument(
    super.name,
    super.arguments,
    super.options,
  );

  static Iterable<NamedAbbreviatedArgument> fromArguments(
    String name,
    List<String> arguments,
  ) {
    final n = name.substring(1);
    final poargs = NamedArgument.resolvePositionalArguments(arguments);
    final params = NamedArgument.resolveParameterArguments(arguments);
    final flags = n.split('');
    return flags.map<NamedAbbreviatedArgument>((flag) {
      return NamedAbbreviatedArgument(
        flag,
        poargs,
        params,
      );
    });
  }

  @override
  Map<String, Object> toJson() {
    return {
      'AbbreviatedNamedParameter': {
        'name': name,
        'arguments': arguments.map((e) => e.toJson()).toList(),
        'options': options.map((e) => e.toJson()).toList(),
      }
    };
  }

  @override
  String toString() {
    return 'AbbreviatedNamedParameter(name: $name, arguments: $arguments, options: $options)';
  }

  @override
  List<Object?> get props => [
        name,
        arguments,
        options,
      ];

  @override
  bool get isPosition => false;

  @override
  bool get isNamed => true;

  @override
  bool get isAbbreviatedNamed => true;

  @override
  String toRawString() {
    return '-$name';
  }
}
