import 'package:vet45_shared_application/application.dart';

import 'evaluate_sales_manual_price_query.dart';

final class EvaluateSalesManualPriceQueryValidator
    implements ICommandValidator<EvaluateSalesManualPriceQuery> {
  @override
  Future<void> validate(EvaluateSalesManualPriceQuery query) async {
    if (query.tenantId.trim().isEmpty || query.storeId.trim().isEmpty) {
      throw ValidationException('Tenant and store are required.');
    }
    if (query.customerId != null && query.customerId!.trim().isEmpty) {
      throw ValidationException('Customer id cannot be blank.');
    }
    if (query.productId.trim().isEmpty || query.productUnitId.trim().isEmpty) {
      throw ValidationException('Product and product unit are required.');
    }
    if (query.quantityMicros <= 0) {
      throw ValidationException('Quantity must be positive.');
    }
    if (query.currencyCode != 'VND') {
      throw ValidationException('Only VND pricing is supported.');
    }
    if (query.contextVersion < 0) {
      throw ValidationException('Context version cannot be negative.');
    }
    if (query.manualIntentCount != 1) {
      throw ValidationException(
        'Exactly one manual pricing intent is required.',
      );
    }
    if ((query.manualUnitPriceMinor ?? 0) < 0 ||
        (query.manualDiscountMinor ?? 0) < 0) {
      throw ValidationException('Manual monetary values cannot be negative.');
    }
    final basisPoints = query.manualDiscountBasisPoints;
    if (basisPoints != null && (basisPoints < 0 || basisPoints > 10000)) {
      throw ValidationException('Discount basis points must be in 0..10000.');
    }
  }
}
