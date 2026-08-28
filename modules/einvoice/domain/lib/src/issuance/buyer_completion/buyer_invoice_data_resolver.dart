import 'buyer_type.dart';
import 'effective_buyer_invoice_data.dart';

final class BuyerInvoiceSourceFields {
  const BuyerInvoiceSourceFields({
    required this.buyerType,
    this.name,
    this.email,
    this.taxCode,
    this.address,
  });

  final BuyerType buyerType;
  final String? name;
  final String? email;
  final String? taxCode;
  final String? address;
}

/// Source-precedence merge (BR-05/07/13/15): base wins; completionSource only
/// fills fields that are null/blank in base. Base buyerType is authoritative.
abstract final class BuyerInvoiceDataResolver {
  static EffectiveBuyerInvoiceData resolve({
    required BuyerInvoiceSourceFields base,
    BuyerInvoiceSourceFields? completionSource,
  }) {
    String? pick(String? baseValue, String? sourceValue) {
      final b = baseValue?.trim();
      if (b != null && b.isNotEmpty) return baseValue;
      final s = sourceValue?.trim();
      if (s != null && s.isNotEmpty) return sourceValue;
      return null;
    }

    return EffectiveBuyerInvoiceData(
      buyerType: base.buyerType,
      name: pick(base.name, completionSource?.name) ?? '',
      email: pick(base.email, completionSource?.email),
      taxCode: pick(base.taxCode, completionSource?.taxCode),
      address: pick(base.address, completionSource?.address),
    );
  }
}
