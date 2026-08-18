import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_einvoice_domain/domain.dart';

@ModuleManifest(
  name: 'einvoice',
  permissions: [
    EInvoicePermissions.manageConfiguration,
    EInvoicePermissions.issue,
    EInvoicePermissions.view,
    EInvoicePermissions.downloadDocument,
    EInvoicePermissions.send,
  ],
)
final class EinvoiceModuleDefinition {}
