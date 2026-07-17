import 'dart:convert';

import 'package:vet45_shared_application/application.dart';

import '../../../../shared/pricing_blocked_codes.dart';
import '../../../../shared/pricing_blocked_exception.dart';
import 'get_customer_price_rule_import_query.dart';

final class GetCustomerPriceRuleImportQueryValidator
    implements ICommandValidator<GetCustomerPriceRuleImportQuery> {
  @override
  Future<void> validate(GetCustomerPriceRuleImportQuery query) async {
    final fieldErrors = <String, String>{};
    if (query.tenantId.trim().isEmpty) {
      fieldErrors['tenantId'] = 'required';
    }
    if (query.importId.trim().isEmpty) {
      fieldErrors['importId'] = 'required';
    }
    if (query.limit < 1 || query.limit > 100) {
      fieldErrors['limit'] = 'out_of_range';
    }
    if (query.cursor != null && !_isValidBase64UrlJson(query.cursor!)) {
      fieldErrors['cursor'] = 'invalid_cursor';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid import get payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }

  bool _isValidBase64UrlJson(String cursor) {
    try {
      final normalized = base64Url.normalize(cursor);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      return payload is Map &&
          payload['rowNumber'] is int &&
          payload['id'] is String &&
          (payload['id'] as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
