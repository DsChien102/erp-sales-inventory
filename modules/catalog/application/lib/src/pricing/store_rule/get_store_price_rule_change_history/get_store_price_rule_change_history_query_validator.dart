import 'package:vet45_shared_application/application.dart';

import 'get_store_price_rule_change_history_query.dart';

final class GetStorePriceRuleChangeHistoryQueryValidator
    implements ICommandValidator<GetStorePriceRuleChangeHistoryQuery> {
  @override
  Future<void> validate(GetStorePriceRuleChangeHistoryQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant is required.');
    }
    if (query.limit < 1 || query.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100.');
    }
    if (query.offset < 0) {
      throw ValidationException('Offset must be zero or greater.');
    }
  }
}
