import 'money_dto.dart';

final class PricingSnapshotDto {
  const PricingSnapshotDto({
    required this.unitPrice,
    required this.source,
    required this.pricedAt,
    this.sourceVersion,
  });

  final MoneyDto unitPrice;
  final String source;
  final DateTime pricedAt;
  final int? sourceVersion;
}
