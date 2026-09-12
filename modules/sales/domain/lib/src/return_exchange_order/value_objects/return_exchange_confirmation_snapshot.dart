import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Immutable confirmation evidence captured at draft → confirmed.
final class ReturnExchangeConfirmationSnapshot extends ValueObject {
  ReturnExchangeConfirmationSnapshot({
    required this.sourceOrderVersion,
    required this.sourceSettlementVersion,
    this.pricingSourceVersion,
    this.inventorySourceVersion,
    required this.confirmedBy,
    required this.confirmedAt,
    this.entrySource,
  }) {
    if (sourceOrderVersion <= 0 || sourceSettlementVersion <= 0) {
      throw DomainException(
        'Confirmation requires positive source order and settlement versions.',
      );
    }
    if (pricingSourceVersion != null && pricingSourceVersion! <= 0) {
      throw DomainException(
        'Pricing source version must be positive when provided.',
      );
    }
    if (inventorySourceVersion != null && inventorySourceVersion! <= 0) {
      throw DomainException(
        'Inventory source version must be positive when provided.',
      );
    }
    if (confirmedBy.trim().isEmpty) {
      throw DomainException('Confirmation requires a confirmedBy actor.');
    }
  }

  final int sourceOrderVersion;
  final int sourceSettlementVersion;
  final int? pricingSourceVersion;
  final int? inventorySourceVersion;
  final String confirmedBy;
  final DateTime confirmedAt;

  /// Server-derived initiation/correlation hint; nullable when frozen contract
  /// cannot supply an explicit client field.
  final String? entrySource;

  @override
  List<Object?> get props => <Object?>[
    sourceOrderVersion,
    sourceSettlementVersion,
    pricingSourceVersion,
    inventorySourceVersion,
    confirmedBy,
    confirmedAt,
    entrySource,
  ];
}
