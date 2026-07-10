/// Application-layer failure with a stable blocked code for UI mapping.
final class PartnerBlockedException implements Exception {
  const PartnerBlockedException(this.code, {this.message, this.details});

  final String code;
  final String? message;
  final Map<String, Object?>? details;

  @override
  String toString() => message ?? code;
}
