import '../../shared/customer_price_rule_detail_dto.dart';
import '../../shared/rule_issue_dto.dart';

final class CreateCustomerPriceRuleResult {
  const CreateCustomerPriceRuleResult({
    required this.rule,
    required this.warnings,
  });

  final CustomerPriceRuleDetailDto rule;
  final List<RuleIssueDto> warnings;
}
