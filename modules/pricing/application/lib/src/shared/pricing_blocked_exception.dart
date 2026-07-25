final class PricingBlockedException implements Exception {
  const PricingBlockedException(
    this.code, {
    this.message,
    this.details = const {},
  });

  final String code;
  final String? message;
  final Map<String, Object?> details;

  @override
  String toString() => 'PricingBlockedException($code, $message, $details)';
}
