/// Application-layer failure with a stable blocked code for UI mapping.
final class IamBlockedException implements Exception {
  const IamBlockedException(this.code, {this.message, this.details});

  final String code;
  final String? message;
  final Map<String, Object?>? details;

  @override
  String toString() => message ?? code;
}
