/// Validates [EmailDeliveryRequestedIntegrationEvent.refs] during deserialization.
Map<String, String> emailDeliveryRefsFromJson(Object? json) {
  final refs = <String, String>{};
  if (json is! Map) {
    return refs;
  }

  for (final entry in json.entries) {
    final key = entry.key.toString();
    final value = entry.value.toString();
    _rejectSecretInRefs(key, value);
    refs[key] = value;
  }
  return refs;
}

void _rejectSecretInRefs(String key, String value) {
  final lowerKey = key.toLowerCase();
  const banned = <String>{
    'token',
    'raw_token',
    'otp',
    'password',
    'code',
    'session_token',
    'invitation_token',
  };
  if (banned.contains(lowerKey)) {
    throw FormatException('refs must not contain secret material key=$key');
  }
  if (value.length >= 16 &&
      RegExp(r'^[A-Za-z0-9\-_=+/]+$').hasMatch(value) &&
      lowerKey.contains('token')) {
    throw FormatException(
      'refs must not contain token-like secret material key=$key',
    );
  }
}
