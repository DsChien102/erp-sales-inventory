Map<String, dynamic> iamJsonMap(dynamic result) {
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is List && result.isNotEmpty && result.first is Map) {
    return Map<String, dynamic>.from(result.first as Map);
  }
  return const {};
}

DateTime? iamTimestamp(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.parse(value.toString()).toUtc();
}

List<String> iamStringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).toList(growable: false);
}
