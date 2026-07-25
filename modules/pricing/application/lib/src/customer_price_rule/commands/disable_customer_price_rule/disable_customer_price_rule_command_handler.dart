import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_command_gateway.dart';
import '../../shared/customer_price_rule_detail_dto.dart';
import 'disable_customer_price_rule_command.dart';

@CommandHandlerFor(DisableCustomerPriceRuleCommand)
final class DisableCustomerPriceRuleCommandHandler
    implements
        ICommandHandler<
          DisableCustomerPriceRuleCommand,
          CustomerPriceRuleDetailDto
        > {
  const DisableCustomerPriceRuleCommandHandler({
    required ICustomerPriceRuleCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ICustomerPriceRuleCommandGateway _commandGateway;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    DisableCustomerPriceRuleCommand command,
  ) => _commandGateway.disable(
    tenantId: command.tenantId,
    ruleId: command.ruleId.trim(),
    expectedVersion: command.expectedVersion,
    reason: _normalizeReason(command.reason),
  );

  String? _normalizeReason(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
