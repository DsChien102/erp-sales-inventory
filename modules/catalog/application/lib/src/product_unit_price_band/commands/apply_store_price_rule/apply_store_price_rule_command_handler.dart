import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_read_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_readiness_read_port.dart';
import 'package:vet45_catalog_application/src/ports/i_store_price_rule_gateway.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'apply_store_price_rule_command.dart';
import 'apply_store_price_rule_result.dart';

@CommandHandlerFor(ApplyStorePriceRuleCommand)
final class ApplyStorePriceRuleCommandHandler
    implements ICommandHandler<ApplyStorePriceRuleCommand, ApplyStorePriceRuleResult> {
  ApplyStorePriceRuleCommandHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
    required IProductReadinessReadPort readinessReadPort,
    required ICatalogReadGateway catalogReadGateway,
  }) : _storePriceRuleGateway = storePriceRuleGateway,
       _readinessReadPort = readinessReadPort,
       _catalogReadGateway = catalogReadGateway;

  final IStorePriceRuleGateway _storePriceRuleGateway;
  final IProductReadinessReadPort _readinessReadPort;
  final ICatalogReadGateway _catalogReadGateway;

  @override
  Future<ApplyStorePriceRuleResult> handle(ApplyStorePriceRuleCommand command) async {
    final ruleDto = await _storePriceRuleGateway.getRule(tenantId: command.tenantId);
    if (ruleDto == null) {
      throw ApplicationException('Store price rule not found');
    }

    final controlCenter = await _catalogReadGateway.loadControlCenter(
      tenantId: command.tenantId,
      productId: command.productId,
    );
    final basePrice = controlCenter?.basePriceAmount;
    if (basePrice == null) {
      throw MissingBasePriceException();
    }

    final rule = StorePriceRule.create(
      id: ruleDto.id,
      tenantId: command.tenantId,
      name: ruleDto.name,
      listMarkupRatio: ruleDto.listMarkupRatio,
      floorMarkupRatio: ruleDto.floorMarkupRatio,
      isActive: true,
    );
    final suggested = rule.suggestPrices(basePrice);

    // Domain-first: validate suggested band before RPC persist.
    ProductUnitPriceBand.set(
      id: '${command.productId}_${command.productUnitId ?? 'base'}',
      tenantId: TenantId(command.tenantId),
      productId: ProductId(command.productId),
      productUnitId: command.productUnitId ?? 'base',
      listPrice: suggested.listPrice,
      floorPrice: suggested.floorPrice,
      storePriceRuleId: ruleDto.id,
    );

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
