import 'package:vet45_shared_application/application.dart';

import '../../ports/i_store_price_rule_gateway.dart';
import 'set_store_price_rule_command.dart';
import 'set_store_price_rule_result.dart';

@CommandHandlerFor(SetStorePriceRuleCommand)
final class SetStorePriceRuleCommandHandler
    implements ICommandHandler<SetStorePriceRuleCommand, SetStorePriceRuleResult> {
  SetStorePriceRuleCommandHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
  }) : _storePriceRuleGateway = storePriceRuleGateway;

  final IStorePriceRuleGateway _storePriceRuleGateway;

  @override
  Future<SetStorePriceRuleResult> handle(SetStorePriceRuleCommand command) async {
    final rule = await _storePriceRuleGateway.upsertRule(
      tenantId: command.tenantId,
      name: command.name,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
      status: command.status,
    );
    return SetStorePriceRuleResult(rule: rule);
  }
}
