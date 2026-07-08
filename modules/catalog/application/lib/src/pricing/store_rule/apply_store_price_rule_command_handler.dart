import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../ports/i_product_readiness_read_port.dart';
import '../../ports/i_store_price_rule_gateway.dart';
import '../../readiness/readiness_summary_dto.dart';
import 'apply_store_price_rule_command.dart';
import 'apply_store_price_rule_result.dart';

@CommandHandlerFor(ApplyStorePriceRuleCommand)
final class ApplyStorePriceRuleCommandHandler
    implements ICommandHandler<ApplyStorePriceRuleCommand, ApplyStorePriceRuleResult> {
  ApplyStorePriceRuleCommandHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
    required IProductReadinessReadPort readinessReadPort,
  }) : _storePriceRuleGateway = storePriceRuleGateway,
       _readinessReadPort = readinessReadPort;

  final IStorePriceRuleGateway _storePriceRuleGateway;
  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<ApplyStorePriceRuleResult> handle(ApplyStorePriceRuleCommand command) async {
    final applied = await _storePriceRuleGateway.apply(command: command);

    final facts = await _readinessReadPort.loadFacts(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }

    final readiness = ProductReadinessEvaluator.compute(facts);
    return ApplyStorePriceRuleResult(
      productId: applied.productId,
      productUnitId: applied.productUnitId,
      listPrice: applied.listPrice,
      floorPrice: applied.floorPrice,
      storePriceRuleId: applied.storePriceRuleId,
      sourceType: applied.sourceType,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
    );
  }
}
