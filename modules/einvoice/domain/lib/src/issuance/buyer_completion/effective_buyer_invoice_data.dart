import 'package:equatable/equatable.dart';

import 'buyer_type.dart';

/// Effective buyer data resolved for invoice issuance and completion evaluation.
final class EffectiveBuyerInvoiceData extends Equatable {
  const EffectiveBuyerInvoiceData({
    required this.buyerType,
    required this.name,
    this.email,
    this.taxCode,
    this.address,
  });

  final BuyerType buyerType;
  final String name;
  final String? email;
  final String? taxCode;
  final String? address;

  /// Whether required fields are satisfied based on buyer classification:
  /// - Retail/Individual: only non-empty name required.
  /// - Organization: requires non-empty name and non-empty taxCode.
  bool get isComplete {
    final hasName = name.trim().isNotEmpty;
    if (!hasName) return false;

    switch (buyerType) {
      case BuyerType.retail:
      case BuyerType.individual:
        return true;
      case BuyerType.organization:
        return (taxCode != null) && taxCode!.trim().isNotEmpty;
    }
  }

  /// True when organization has a valid name but missing or empty tax code (BR-08 / UI-06).
  bool get isMissingOnlyOrgTaxCode =>
      buyerType == BuyerType.organization &&
      name.trim().isNotEmpty &&
      (taxCode?.trim().isEmpty ?? true);

  @override
  List<Object?> get props => [buyerType, name, email, taxCode, address];
}
