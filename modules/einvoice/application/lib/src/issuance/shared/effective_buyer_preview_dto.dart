/// Preview of effective buyer invoice data after completion.
final class EffectiveBuyerPreviewDto {
  const EffectiveBuyerPreviewDto({
    required this.name,
    this.email,
    this.taxCode,
    this.address,
  });

  final String name;
  final String? email;
  final String? taxCode;
  final String? address;
}
