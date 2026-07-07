import 'query_key.dart';

/// Produces a stable string hash for [queryKey] values.
String hashQueryKey(QueryKey queryKey) {
  return _QueryKeyHasher().hash(queryKey);
}

final class _QueryKeyHasher {
  int _hash(Object? value) {
    if (value == null) return 0;
    if (value is bool) return value ? 1 : 2;
    if (value is int) return value.hashCode;
    if (value is double) return value.hashCode;
    if (value is String) return value.hashCode;
    if (value is Enum) return Object.hash(value.runtimeType, value.index);
    if (value is DateTime) return value.millisecondsSinceEpoch.hashCode;
    if (value is Duration) return value.inMicroseconds.hashCode;
    if (value is List) {
      var result = 17;
      for (final item in value) {
        result = Object.hash(result, _hash(item));
      }
      return result;
    }
    if (value is Map) {
      var result = 19;
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      for (final entry in entries) {
        result = Object.hash(result, _hash(entry.key), _hash(entry.value));
      }
      return result;
    }
    if (value is Iterable) {
      var result = 23;
      for (final item in value) {
        result = Object.hash(result, _hash(item));
      }
      return result;
    }
    return Object.hash(value.runtimeType, value.toString());
  }

  String hash(QueryKey queryKey) {
    final buffer = StringBuffer();
    for (var i = 0; i < queryKey.length; i++) {
      if (i > 0) buffer.write('|');
      buffer.write(_hash(queryKey[i]));
    }
    return buffer.toString();
  }
}

bool queryKeyMatchesFilter(QueryKey queryKey, QueryKeyFilter filter) {
  if (filter.length > queryKey.length) return false;
  for (var i = 0; i < filter.length; i++) {
    if (!_valuesEqual(queryKey[i], filter[i])) return false;
  }
  return true;
}

bool _valuesEqual(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_valuesEqual(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_valuesEqual(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
