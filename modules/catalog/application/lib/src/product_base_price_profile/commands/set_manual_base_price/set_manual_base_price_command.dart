import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_manual_base_price_result.dart';

@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class SetManualBasePriceCommand extends CommandBase<SetManualBasePriceResult>
    implements ICommand<SetManualBasePriceResult>, ITenantScopedCommand {
  SetManualBasePriceCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.basePrice,
    this.currency = 'VND',
    this.mode = 'manual',
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final double basePrice;
  final String currency;
  final String mode;
}
