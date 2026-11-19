int asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}

DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime asRequiredDateTime(dynamic value) {
  return asDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String? asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

extension JsonMapCoercion on Map<String, dynamic> {
  int readInt(
    String key, {
    int fallback = 0,
    List<String> aliases = const [],
  }) {
    return asInt(_resolve(key, aliases), fallback: fallback);
  }

  double readDouble(
    String key, {
    double fallback = 0,
    List<String> aliases = const [],
  }) {
    return asDouble(_resolve(key, aliases), fallback: fallback);
  }

  DateTime? readDateTime(
    String key, {
    List<String> aliases = const [],
  }) {
    return asDateTime(_resolve(key, aliases));
  }

  DateTime readRequiredDateTime(
    String key, {
    List<String> aliases = const [],
  }) {
    return asRequiredDateTime(_resolve(key, aliases));
  }

  String? readNullableString(
    String key, {
    List<String> aliases = const [],
  }) {
    return asNullableString(_resolve(key, aliases));
  }

  dynamic _resolve(String key, List<String> aliases) {
    if (containsKey(key)) {
      return this[key];
    }

    for (final alias in aliases) {
      if (containsKey(alias)) {
        return this[alias];
      }
    }

    return null;
  }
}
