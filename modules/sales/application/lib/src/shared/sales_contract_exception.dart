final class SalesContractException implements Exception {
  const SalesContractException(
    this.code, {
    this.message,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String? message;
  final Map<String, Object?> details;

  @override
  String toString() => 'SalesContractException($code${message == null ? '' : ': $message'})';
}
