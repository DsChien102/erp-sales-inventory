import 'dart:typed_data';

import 'package:vet45_pricing_domain/domain.dart'
    hide CustomerPriceRuleImportMode;
import 'package:vet45_shared_application/application.dart';

import '../../shared/customer_price_rule_import_detail_dto.dart';
import '../../shared/customer_price_rule_import_enums.dart';

@RequiresPermission(PricingPermissions.importCustomerPriceRule)
@RequiresTenant()
final class StartCustomerPriceRuleImportCommand
    extends CommandBase<CustomerPriceRuleImportDetailDto>
    implements
        ICommand<CustomerPriceRuleImportDetailDto>,
        ITenantScopedCommand {
  StartCustomerPriceRuleImportCommand({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.templateVersion,
    required this.originalFileName,
    required this.fileBytes,
    required this.importMode,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String templateVersion;
  final String originalFileName;
  final Uint8List fileBytes;
  final CustomerPriceRuleImportMode importMode;

  StartCustomerPriceRuleImportCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => StartCustomerPriceRuleImportCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    templateVersion: templateVersion,
    originalFileName: originalFileName,
    fileBytes: fileBytes,
    importMode: importMode,
  );
}
