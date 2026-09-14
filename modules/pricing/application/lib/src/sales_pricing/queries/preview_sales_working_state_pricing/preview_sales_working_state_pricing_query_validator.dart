import 'package:vet45_shared_application/application.dart';

import '../../shared/sales_pricing_line_input.dart';
import 'preview_sales_working_state_pricing_query.dart';

final class PreviewSalesWorkingStatePricingQueryValidator
    implements ICommandValidator<PreviewSalesWorkingStatePricingQuery> {
  @override
  Future<void> validate(PreviewSalesWorkingStatePricingQuery query) async {
    if (query.tenantId.trim().isEmpty || query.storeId.trim().isEmpty) {
      throw ValidationException('Tenant and store are required.');
    }
    if (query.customerId != null && query.customerId!.trim().isEmpty) {
      throw ValidationException('Customer id cannot be blank.');
    }
    if (query.currencyCode != 'VND') {
      throw ValidationException('Only VND pricing is supported.');
    }
    if (!query.effectiveAt.isUtc) {
      throw ValidationException('Effective time must be UTC.');
    }
    if (query.contextVersion < 0) {
      throw ValidationException('Context version cannot be negative.');
    }
    if (query.lines.isEmpty) {
      throw ValidationException('At least one pricing line is required.');
    }

    final ids = <String>{};
    for (final line in query.lines) {
      _validateLine(line);
      if (!ids.add(line.localLineId)) {
        throw ValidationException('Local line ids must be unique.');
      }
    }
  }

  static void _validateLine(SalesPricingLineInput line) {
    if (line.localLineId.trim().isEmpty ||
        line.productId.trim().isEmpty ||
        line.productUnitId.trim().isEmpty) {
      throw ValidationException('Pricing line identifiers are required.');
    }
    if (line.quantityMicros <= 0) {
      throw ValidationException('Quantity must be positive.');
    }
    if (line.manualIntentCount > 1) {
      throw ValidationException('Only one manual pricing intent is allowed.');
    }
    if ((line.manualUnitPriceMinor ?? 0) < 0 ||
        (line.manualDiscountMinor ?? 0) < 0) {
      throw ValidationException('Manual monetary values cannot be negative.');
    }
    final basisPoints = line.manualDiscountBasisPoints;
    if (basisPoints != null && (basisPoints < 0 || basisPoints > 10000)) {
      throw ValidationException('Discount basis points must be in 0..10000.');
    }
  }
}
