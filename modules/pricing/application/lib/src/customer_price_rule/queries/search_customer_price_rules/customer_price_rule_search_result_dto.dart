import '../../shared/cursor_page_dto.dart';
import 'customer_price_rule_list_item_dto.dart';

abstract final class PricingAvailableActions {
  static const createManual = 'create_manual';
  static const import = 'import';
}

final class CustomerPriceRuleSearchResultDto {
  const CustomerPriceRuleSearchResultDto({
    required this.page,
    required this.availableActions,
  });

  final CursorPageDto<CustomerPriceRuleListItemDto> page;
  final List<String> availableActions;
}
