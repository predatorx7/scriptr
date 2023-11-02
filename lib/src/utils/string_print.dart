String toStringForListOr(Iterable<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  final buffer = StringBuffer();
  for (var i = 0; i < items.length; i++) {
    if (i != 0) {
      buffer.write(' ');
    }
    if (i == items.length - 1) {
      buffer.write('or ');
    }
    buffer.write(items.elementAt(i));
    if (i < items.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
