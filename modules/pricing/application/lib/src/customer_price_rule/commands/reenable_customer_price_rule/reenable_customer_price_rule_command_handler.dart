import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_command_gateway.dart';
import '../../shared/customer_price_rule_detail_dto.dart';
import 'reenable_customer_price_rule_command.dart';

@CommandHandlerFor(ReenableCustomerPriceRuleCommand)
final class ReenableCustomerPriceRuleCommandHandler
    implements
        ICommandHandler<
          ReenableCustomerPriceRuleCommand,
          CustomerPriceRuleDetailDto
        > {
  const ReenableCustomerPriceRuleCommandHandler({
    required ICustomerPriceRuleCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ICustomerPriceRuleCommandGateway _commandGateway;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    ReenableCustomerPriceRuleCommand command,
  ) => _commandGateway.reenable(
    tenantId: command.tenantId,
    ruleId: command.ruleId.trim(),
    expectedVersion: command.expectedVersion,
    businessDate: command.businessDate,
    precheckToken: command.precheckToken,
    acknowledgeFloorWarning: command.acknowledgeFloorWarning,
  );
}
