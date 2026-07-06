import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(CatalogPermissions.managePricing)
@RequiresTenant()
final class SetManualBasePriceCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  SetManualBasePriceCommand({
    String? id,
    required this.tenantId,
    required this.productId,
    required this.basePrice,
    this.currency = 'VND',
  }) : super(id);

  @override
  final String tenantId;
  final String productId;
  final double basePrice;
  final String currency;
}
