import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_customer_price_rule_reenable_precheck_port.dart';
import 'customer_price_rule_reenable_precheck_dto.dart';
import 'precheck_customer_price_rule_reenable_query.dart';
import 'precheck_customer_price_rule_reenable_query_validator.dart';

@QueryHandlerFor(PrecheckCustomerPriceRuleReenableQuery)
final class PrecheckCustomerPriceRuleReenableQueryHandler
    implements
        IQueryHandler<
          PrecheckCustomerPriceRuleReenableQuery,
          CustomerPriceRuleReenablePrecheckDto
        > {
  const PrecheckCustomerPriceRuleReenableQueryHandler({
    required ICustomerPriceRuleReenablePrecheckPort precheckPort,
    required PrecheckCustomerPriceRuleReenableQueryValidator validator,
  }) : _precheckPort = precheckPort,
       _validator = validator;

  final ICustomerPriceRuleReenablePrecheckPort _precheckPort;
  final PrecheckCustomerPriceRuleReenableQueryValidator _validator;

  @override
  Future<CustomerPriceRuleReenablePrecheckDto> handle(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) async {
    await _validator.validate(query);
    return _precheckPort.precheck(query);
  }
}
