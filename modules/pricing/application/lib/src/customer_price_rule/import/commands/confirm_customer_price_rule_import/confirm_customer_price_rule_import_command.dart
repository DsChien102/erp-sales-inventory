import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_import_result_dto.dart';

@RequiresPermission(PricingPermissions.importCustomerPriceRule)
@RequiresTenant()
final class ConfirmCustomerPriceRuleImportCommand
    extends CommandBase<CustomerPriceRuleImportResultDto>
    implements
        ICommand<CustomerPriceRuleImportResultDto>,
        ITenantScopedCommand {
  ConfirmCustomerPriceRuleImportCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.importId,
    required this.expectedVersion,
    required DateTime businessDate,
    required this.acknowledgeWarningRows,
  }) : businessDate = DateTime.utc(
         businessDate.year,
         businessDate.month,
         businessDate.day,
       ),
       super(id);

  @override
  final String tenantId;
  final String actorId;
  final String importId;
  final int expectedVersion;
  final DateTime businessDate;
  final bool acknowledgeWarningRows;

  ConfirmCustomerPriceRuleImportCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => ConfirmCustomerPriceRuleImportCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    importId: importId,
    expectedVersion: expectedVersion,
    businessDate: businessDate,
    acknowledgeWarningRows: acknowledgeWarningRows,
  );
}
