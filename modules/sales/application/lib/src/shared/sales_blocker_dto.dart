final class SalesBlockerDto {
  const SalesBlockerDto({
    required this.code,
    required this.message,
    this.field,
  });

  final String code;
  final String message;
  final String? field;
}
