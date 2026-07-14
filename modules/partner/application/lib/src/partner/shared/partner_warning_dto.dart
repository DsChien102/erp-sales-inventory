/// Warning returned on successful mutations (e.g. duplicate hints).
final class PartnerWarningDto {
  const PartnerWarningDto({
    required this.code,
    this.field,
    required this.message,
  });

  final String code;
  final String? field;
  final String message;
}
