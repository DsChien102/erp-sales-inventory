import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';
import 'package:vet45_sales_application/application.dart';

/// Chép điều kiện + câu của FinalizeSalesOrderCommandValidator (bỏ kiểm tenantId / actorId).
void checkFinalize({
  required String storeId,
  required String currencyCode,
  required String idempotencyKey,
  required String payloadHash,
  required String correlationId,
  required List<CheckoutLineInput> lines,
  required List<PaymentIntentInput> paymentIntents,
}) {
  _requireNotBlank(storeId, 'storeId');
  _requireNotBlank(currencyCode, 'currencyCode');
  _requireNotBlank(idempotencyKey, 'idempotencyKey');
  _requireNotBlank(payloadHash, 'payloadHash');
  _requireNotBlank(correlationId, 'correlationId');
  if (lines.isEmpty) _fail('Finalize checkout requires at least one line.');
  for (final line in lines) {
    _requireNotBlank(line.productId, 'productId');
    _requireNotBlank(line.productUnitId, 'productUnitId');
    if (line.quantity.quantityMicros <= 0) _fail('Checkout line quantity must be positive.');
  }
  for (final intent in paymentIntents) {
    if (intent.amount.amountMinor <= 0) {
      _fail('Payment intent amount must be greater than zero.');
    }
    _requireNotBlank(intent.amount.currencyCode, 'paymentCurrencyCode');
  }
}

void _requireNotBlank(String value, String field) {
  if (value.trim().isEmpty) _fail('$field is required.');
}

Never _fail(String message) =>
    throw AppException(SalesCheckoutErrorCodes.contextInvalid, serverMessage: message);
