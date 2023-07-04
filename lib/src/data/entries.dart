const _reservedKeys = <String>['about', 'alias', 'info', 'flags', 'options'];

Map<String, Object?> withoutReservedEntries(Map<String, Object?>? data) {
  return removeReservedEntries({
    ...?data,
  });
}

Map<String, Object?> removeReservedEntries(Map<String, Object?> data) {
  return data
    ..removeWhere(
      (key, value) => _reservedKeys.contains(key) || key.startsWith('call('),
    );
}

Map<String, Object?> getFunctionEntries(Map<String, Object?> data) {
  return Map.fromEntries(data.entries.where(
    (entry) => entry.key.startsWith('call('),
  ));
}
