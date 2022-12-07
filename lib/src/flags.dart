bool hasFlag(
  List<String> arguments,
  String name,
  String abbreviation,
) {
  final flags = arguments.where((arg) => arg.startsWith('-'));
  for (final arg in flags) {
    if (arg.startsWith('--$name')) {
      return true;
    } else if (!arg.startsWith('--') && arg.contains(abbreviation)) {
      return true;
    }
  }
  return false;
}
