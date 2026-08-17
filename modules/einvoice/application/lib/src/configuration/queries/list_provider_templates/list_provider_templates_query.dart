import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'provider_template_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class ListProviderTemplatesQuery extends QueryBase<List<ProviderTemplateDto>>
    implements IQuery<List<ProviderTemplateDto>>, ITenantScopedCommand {
  ListProviderTemplatesQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
    this.invoiceWithCode,
    this.year,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final bool? invoiceWithCode;
  final int? year;
}
