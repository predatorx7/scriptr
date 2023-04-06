class ScriptrError {
  final String message;

  const ScriptrError(this.message);

  @override
  String toString() {
    return '$runtimeType: $message';
  }

  factory ScriptrError.merge(
    List<ScriptrError> errors, {
    String reason = '',
    String? lastMessage,
  }) {
    final errorTypes = errors.map((e) => e.runtimeType).toSet();
    final buffer = StringBuffer(reason);
    for (final errorType in errorTypes) {
      buffer.writeln('\n$errorType: ');
      final errorsOfType = errors.where((it) => it.runtimeType == errorType);
      final errorMessagesOfType = errorsOfType
          .map((e) => e.message)
          .map((e) => '  ${e.replaceAll('\n', '\n  ')}');
      final completeErrorMessage = errorMessagesOfType.join('\n');
      buffer.writeln(completeErrorMessage);
    }
    if (lastMessage != null) {
      buffer.writeln(lastMessage);
    }
    final message = buffer.toString();
    return ScriptrError(message);
  }
}

class ConfigNotFound extends ScriptrError {
  const ConfigNotFound(super.message);
}

class InvalidConfig extends ScriptrError {
  const InvalidConfig(super.message);
}
