import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_sales_domain/domain.dart';

@ModuleManifest(
  name: 'sales',
  permissions: [
    SalesPermissions.createDraft,
    SalesPermissions.updateDraft,
    SalesPermissions.deleteDraft,
    SalesPermissions.restoreDraft,
    SalesPermissions.finalizeCheckout,
    SalesPermissions.viewOrder,
    SalesPermissions.viewOrderHistory,
    SalesPermissions.cancelOrder,
    SalesPermissions.viewPayment,
    SalesPermissions.recordPayment,
    SalesPermissions.refundPayment,
    SalesPermissions.viewReceipt,
    SalesPermissions.generateReceipt,
    SalesPermissions.printReceipt,
    SalesPermissions.shareReceipt,
    SalesPermissions.archiveReceipt,
    SalesPermissions.createReturnExchange,
    SalesPermissions.updateReturnExchange,
    SalesPermissions.cancelReturnExchange,
    SalesPermissions.confirmReturnExchange,
    SalesPermissions.completeReturnExchange,
    SalesPermissions.viewReturnExchange,
  ],
)
final class SalesModuleDefinition {}
