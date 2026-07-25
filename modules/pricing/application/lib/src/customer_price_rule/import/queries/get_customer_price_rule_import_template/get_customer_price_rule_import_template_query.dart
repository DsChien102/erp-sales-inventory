import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_import_template_dto.dart';

@RequiresPermission(PricingPermissions.importCustomerPriceRule)
@RequiresTenant()
final class GetCustomerPriceRuleImportTemplateQuery
    extends QueryBase<CustomerPriceRuleImportTemplateDto>
    implements
        IQuery<CustomerPriceRuleImportTemplateDto>,
        ITenantScopedCommand {
  GetCustomerPriceRuleImportTemplateQuery({String? id, this.tenantId = ''})
    : super(id);

  @override
  final String tenantId;

  GetCustomerPriceRuleImportTemplateQuery withExecutionContext({
    required String tenantId,
  }) => GetCustomerPriceRuleImportTemplateQuery(id: id, tenantId: tenantId);
}
