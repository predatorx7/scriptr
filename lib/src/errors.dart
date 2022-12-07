abstract class ScriptrError {
  final String message;

  const ScriptrError(this.message);

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}

class ConfigNotFound extends ScriptrError {
  const ConfigNotFound(super.message);
}

class InvalidConfig extends ScriptrError {
  const InvalidConfig(super.message);
}
