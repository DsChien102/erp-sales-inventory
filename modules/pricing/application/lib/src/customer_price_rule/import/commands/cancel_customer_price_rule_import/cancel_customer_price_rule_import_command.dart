import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_import_dto.dart';

@RequiresPermission(PricingPermissions.importCustomerPriceRule)
@RequiresTenant()
final class CancelCustomerPriceRuleImportCommand
    extends CommandBase<CustomerPriceRuleImportDto>
    implements ICommand<CustomerPriceRuleImportDto>, ITenantScopedCommand {
  CancelCustomerPriceRuleImportCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.importId,
    required this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String importId;
  final int expectedVersion;

  CancelCustomerPriceRuleImportCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => CancelCustomerPriceRuleImportCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    importId: importId,
    expectedVersion: expectedVersion,
  );
}
