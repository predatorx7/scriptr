import 'package:equatable/equatable.dart';

import 'scriptr_utils.dart';

abstract class Argument with EquatableMixin {
  const Argument();

  static Iterable<Argument> parseApplicationArguments(List<String> arguments) {
    final usedConfigFromArguments =
        arguments.isNotEmpty && hasValidConfigFileExtension(arguments.first);
    final applicationArguments =
        usedConfigFromArguments ? arguments.sublist(1) : arguments;

    return Argument.fromArguments(applicationArguments);
  }

  static Iterable<Argument> fromArguments(List<String> arguments) sync* {
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final isParameter = arg.startsWith('-');
      final subArgs = arguments.sublist(i + 1);
      if (isParameter) {
        final isLongParameter = arg.startsWith('--');
        if (isLongParameter) {
          yield NamedParameter.fromArguments(
            arg,
            subArgs,
          );
        } else {
          final params = AbbreviatedNamedParameter.fromArguments(
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
}

abstract class Parameter extends Argument {
  const Parameter();

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

  static Iterable<AbbreviatedNamedParameter> resolveParameterArguments(
    List<String> arguments,
  ) sync* {
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final isParameter = arg.startsWith('-');
      if (isParameter) {
        final anps = AbbreviatedNamedParameter.fromArguments(
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
}

class AbbreviatedNamedParameter extends Parameter {
  final String name;
  final Iterable<PositionalArgument> arguments;
  final Iterable<AbbreviatedNamedParameter> options;

  const AbbreviatedNamedParameter(
    this.name,
    this.arguments,
    this.options,
  );

  static Iterable<AbbreviatedNamedParameter> fromArguments(
    String name,
    List<String> arguments,
  ) {
    final n = name.substring(1);
    final poargs = Parameter.resolvePositionalArguments(arguments);
    final params = Parameter.resolveParameterArguments(arguments);
    return n.split('').map<AbbreviatedNamedParameter>((e) {
      return AbbreviatedNamedParameter(
        n,
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
}

class NamedParameter extends Parameter {
  final String name;
  final Iterable<PositionalArgument> arguments;
  final Iterable<AbbreviatedNamedParameter> options;

  const NamedParameter(
    this.name,
    this.arguments,
    this.options,
  );

  factory NamedParameter.fromArguments(
    String name,
    List<String> arguments,
  ) {
    return NamedParameter(
      Parameter.resolveName(name),
      Parameter.resolvePositionalArguments(arguments),
      Parameter.resolveParameterArguments(arguments),
    );
  }

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
}
