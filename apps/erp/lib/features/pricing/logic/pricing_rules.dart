import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

final RegExp _isoCurrencyPattern = RegExp(r'^[A-Z]{3}$');

final RegExp _precheckTokenPattern = RegExp(r'^[0-9a-fA-F]{64}$');

void checkCreateRule({
  required String customerId,
  required String productId,
  required String productUnitId,
  required String idempotencyKey,
  required int rulePriceMinor,
  required String currencyCode,
  required DateTime effectiveFrom,
  DateTime? effectiveTo,
}) {
  final fieldErrors = <String, String>{};

  if (customerId.trim().isEmpty) {
    fieldErrors['customerId'] = 'required';
  }
  if (productId.trim().isEmpty) {
    fieldErrors['productId'] = 'required';
  }
  if (productUnitId.trim().isEmpty) {
    fieldErrors['productUnitId'] = 'required';
  }
  if (idempotencyKey.trim().isEmpty) {
    fieldErrors['idempotencyKey'] = 'required';
  }
  if (rulePriceMinor <= 0) {
    fieldErrors['rulePriceMinor'] = 'must_be_positive';
  }
  if (!_isoCurrencyPattern.hasMatch(currencyCode.trim().toUpperCase())) {
    fieldErrors['currencyCode'] = 'invalid_currency';
  }
  if (effectiveTo != null &&
      _calendarDateOnly(effectiveTo).isBefore(_calendarDateOnly(effectiveFrom))) {
    fieldErrors['effectiveTo'] = 'before_effective_from';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule payload.',
  );
}

void checkUpdateRule({
  required String ruleId,
  required int expectedVersion,
  required int rulePriceMinor,
  required DateTime effectiveFrom,
  DateTime? effectiveTo,
  String? changeReason,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);
  if (expectedVersion <= 0) {
    fieldErrors['expectedVersion'] = 'must_be_positive';
  }
  if (rulePriceMinor <= 0) {
    fieldErrors['rulePriceMinor'] = 'must_be_positive';
  }
  if (effectiveTo != null &&
      _calendarDateOnly(effectiveTo).isBefore(_calendarDateOnly(effectiveFrom))) {
    fieldErrors['effectiveTo'] = 'before_effective_from';
  }
  if (changeReason != null && changeReason.trim().length > 200) {
    fieldErrors['reason'] = 'too_long';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule update payload.',
  );
}

void checkDisableRule({
  required String ruleId,
  required int expectedVersion,
  String? reason,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);
  if (expectedVersion <= 0) {
    fieldErrors['expectedVersion'] = 'must_be_positive';
  }
  if (reason != null && reason.trim().length > 500) {
    fieldErrors['reason'] = 'too_long';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule disable payload.',
  );
}

void checkReenableRule({
  required String ruleId,
  required int expectedVersion,
  String? precheckToken,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);
  if (expectedVersion <= 0) {
    fieldErrors['expectedVersion'] = 'must_be_positive';
  }
  if (precheckToken != null &&
      !_precheckTokenPattern.hasMatch(precheckToken.trim())) {
    fieldErrors['precheckToken'] = 'invalid';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule reenable payload.',
  );
}

void checkPrecheckReenable({
  required String ruleId,
  required int expectedVersion,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);
  if (expectedVersion <= 0) {
    fieldErrors['expectedVersion'] = 'must_be_positive';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule reenable precheck payload.',
  );
}

void checkRuleId(String ruleId) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule detail payload.',
  );
}

void checkHistoryPage({
  required String ruleId,
  String? cursor,
  required int limit,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'ruleId', ruleId);
  if (limit <= 0 || limit > 100) {
    fieldErrors['limit'] = 'out_of_range';
  }
  if (cursor != null && cursor.trim().length > 1024) {
    fieldErrors['cursor'] = 'too_long';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule history payload.',
  );
}

void checkSearch({
  String? q,
  String? customerId,
  String? productId,
  required int limit,
}) {
  final fieldErrors = <String, String>{};

  if (limit <= 0 || limit > 100) {
    fieldErrors['limit'] = 'out_of_range';
  }
  if (q != null && q.trim().length > 120) {
    fieldErrors['q'] = 'too_long';
  }
  if (customerId != null && customerId.trim().isEmpty) {
    fieldErrors['customerId'] = 'blank';
  }
  if (productId != null && productId.trim().isEmpty) {
    fieldErrors['productId'] = 'blank';
  }

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid customer price rule search payload.',
  );
}

void checkResolve({
  required String customerId,
  required String productId,
  required String productUnitId,
}) {
  final fieldErrors = <String, String>{};

  _validateUuidField(fieldErrors, 'customerId', customerId);
  _validateUuidField(fieldErrors, 'productId', productId);
  _validateUuidField(fieldErrors, 'productUnitId', productUnitId);

  _throwIfFieldErrors(
    fieldErrors,
    serverMessage: 'Invalid resolve applicable customer price rule payload.',
  );
}

void checkSalesPreview({
  required String storeId,
  String? customerId,
  required String currencyCode,
  required DateTime effectiveAt,
  required int contextVersion,
  required List<SalesPricingLineInput> lines,
}) {
  if (storeId.trim().isEmpty) {
    _throwValidationMessage('Tenant and store are required.');
  }
  if (customerId != null && customerId.trim().isEmpty) {
    _throwValidationMessage('Customer id cannot be blank.');
  }
  if (currencyCode.trim().toUpperCase() != 'VND') {
    _throwValidationMessage('Only VND pricing is supported.');
  }
  if (!effectiveAt.isUtc) {
    _throwValidationMessage('Effective time must be UTC.');
  }
  if (contextVersion < 0) {
    _throwValidationMessage('Context version cannot be negative.');
  }
  if (lines.isEmpty) {
    _throwValidationMessage('At least one pricing line is required.');
  }

  final seenLocalLineIds = <String>{};
  for (final line in lines) {
    if (line.localLineId.trim().isEmpty ||
        line.productId.trim().isEmpty ||
        line.productUnitId.trim().isEmpty) {
      _throwValidationMessage('Pricing line identifiers are required.');
    }
    if (!seenLocalLineIds.add(line.localLineId)) {
      _throwValidationMessage('Local line ids must be unique.');
    }
    if (line.quantityMicros <= 0) {
      _throwValidationMessage('Quantity must be positive.');
    }
    if (line.manualIntentCount > 1) {
      _throwValidationMessage('Only one manual pricing intent is allowed.');
    }
    if ((line.manualUnitPriceMinor != null && line.manualUnitPriceMinor! < 0) ||
        (line.manualDiscountMinor != null && line.manualDiscountMinor! < 0)) {
      _throwValidationMessage('Manual monetary values cannot be negative.');
    }
    if (line.manualDiscountBasisPoints != null &&
        (line.manualDiscountBasisPoints! < 0 ||
            line.manualDiscountBasisPoints! > 10000)) {
      _throwValidationMessage('Discount basis points must be in 0..10000.');
    }
  }
}

void checkSalesManualPrice({
  required String storeId,
  String? customerId,
  required String productId,
  required String productUnitId,
  required int quantityMicros,
  required String currencyCode,
  required int contextVersion,
  int? manualUnitPriceMinor,
  int? manualDiscountMinor,
  int? manualDiscountBasisPoints,
}) {
  if (storeId.trim().isEmpty) {
    _throwValidationMessage('Tenant and store are required.');
  }
  if (customerId != null && customerId.trim().isEmpty) {
    _throwValidationMessage('Customer id cannot be blank.');
  }
  if (productId.trim().isEmpty || productUnitId.trim().isEmpty) {
    _throwValidationMessage('Product and product unit are required.');
  }
  if (quantityMicros <= 0) {
    _throwValidationMessage('Quantity must be positive.');
  }
  if (currencyCode.trim().toUpperCase() != 'VND') {
    _throwValidationMessage('Only VND pricing is supported.');
  }
  if (contextVersion < 0) {
    _throwValidationMessage('Context version cannot be negative.');
  }
  final manualIntentCount = [
    manualUnitPriceMinor,
    manualDiscountMinor,
    manualDiscountBasisPoints,
  ].where((value) => value != null).length;
  if (manualIntentCount != 1) {
    _throwValidationMessage('Exactly one manual pricing intent is required.');
  }
  if ((manualUnitPriceMinor != null && manualUnitPriceMinor < 0) ||
      (manualDiscountMinor != null && manualDiscountMinor < 0)) {
    _throwValidationMessage('Manual monetary values cannot be negative.');
  }
  if (manualDiscountBasisPoints != null &&
      (manualDiscountBasisPoints < 0 || manualDiscountBasisPoints > 10000)) {
    _throwValidationMessage('Discount basis points must be in 0..10000.');
  }
}

String? normalizeRuleNote(String? note) {
  if (note == null) {
    return null;
  }
  final trimmed = note.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime _calendarDateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

void _validateUuidField(
  Map<String, String> fieldErrors,
  String field,
  String value,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    fieldErrors[field] = 'required';
  } else if (!_uuidPattern.hasMatch(trimmed)) {
    fieldErrors[field] = 'invalid';
  }
}

void _throwIfFieldErrors(
  Map<String, String> fieldErrors, {
  required String serverMessage,
}) {
  if (fieldErrors.isEmpty) {
    return;
  }
  throw AppException(
    PricingErrorCodes.validationError,
    serverMessage: serverMessage,
    details: Map<String, Object?>.unmodifiable({
      'fieldErrors': Map<String, String>.unmodifiable(fieldErrors),
    }),
  );
}

Never _throwValidationMessage(String message) {
  throw AppException(
    PricingErrorCodes.validationError,
    serverMessage: message,
  );
}
