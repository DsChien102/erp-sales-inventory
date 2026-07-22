import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_command_gateway.dart';
import '../../shared/customer_price_rule_detail_dto.dart';
import 'delete_customer_price_rule_command.dart';

@CommandHandlerFor(DeleteCustomerPriceRuleCommand)
final class DeleteCustomerPriceRuleCommandHandler
    implements
        ICommandHandler<
          DeleteCustomerPriceRuleCommand,
          CustomerPriceRuleDetailDto
        > {
  const DeleteCustomerPriceRuleCommandHandler({
    required ICustomerPriceRuleCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ICustomerPriceRuleCommandGateway _commandGateway;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    DeleteCustomerPriceRuleCommand command,
  ) => _commandGateway.delete(
    tenantId: command.tenantId,
    ruleId: command.ruleId.trim(),
    expectedVersion: command.expectedVersion,
  );
}
