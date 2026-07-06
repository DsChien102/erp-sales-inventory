import 'package:vet45_catalog_domain/domain.dart';

/// Base price card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductBasePriceCardDto {
  const ProductBasePriceCardDto({
    required this.mode,
    this.amount,
    this.currency = 'VND',
    this.isPendingExternal = false,
    this.isMissing = false,
    this.missingMessage,
  });

  final BasePriceMode mode;
  final double? amount;
  final String currency;
  final bool isPendingExternal;
  final bool isMissing;
  final String? missingMessage;
}
