typedef ExecutableAndArguments = ({String executable, List<String> arguments});

ExecutableAndArguments getExecutableAndArguments(String argumentsValue) {
  final args = <String>[];
  final arguments = argumentsValue.trimLeft();
  if (arguments.isEmpty) throw ArgumentError.value(arguments);

  bool isEscaped = false;
  final wordBuffer = StringBuffer();
  String? openedWith;
  for (var i = 0; i < arguments.length; i++) {
    final char = arguments[i];
    if (!isEscaped && char == '\\') {
      isEscaped = true;
      continue;
    } else if (isEscaped) {
      wordBuffer.write(char);
      isEscaped = false;
      continue;
    }
    if (openedWith == char) {
      args.add(wordBuffer.toString());
      openedWith = null;
      wordBuffer.clear();
      continue;
    }
    if (openedWith == null && const ['\'', '"'].contains(char)) {
      openedWith = char;
      continue;
    }
    if (openedWith == null && char == ' ') {
      if (wordBuffer.isEmpty) continue;
      args.add(wordBuffer.toString());
      wordBuffer.clear();
      continue;
    }
    wordBuffer.write(char);
  }
  if (wordBuffer.isNotEmpty) {
    args.add(wordBuffer.toString());
    wordBuffer.clear();
  }

  if (args.isEmpty) throw StateError('Parsed arguments is empty');

  final executable = args.removeAt(0);

  return (executable: executable, arguments: List.unmodifiable(args));
}
