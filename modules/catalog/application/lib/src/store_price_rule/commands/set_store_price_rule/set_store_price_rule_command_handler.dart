import 'package:uuid/uuid.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_store_price_rule_gateway.dart';
import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_status.dart';
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
    // Domain-first validation of markups / name before RPC.
    StorePriceRule.create(
      id: const Uuid().v4(),
      tenantId: command.tenantId,
      name: command.name,
      listMarkupRatio: command.listMarkupRatio,
      floorMarkupRatio: command.floorMarkupRatio,
      isActive: command.status == StorePriceRuleStatus.active,
    );

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
