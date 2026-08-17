/// RBAC permission codes for the einvoice module (TH-08).
/// SRS §6.2.8 defines 11 UI-granular permissions — not split yet.
abstract final class EInvoicePermissions {
  static const manageConfiguration = 'einvoice.manage_configuration';
  static const issue = 'einvoice.issue';
  static const view = 'einvoice.view';
  static const downloadDocument = 'einvoice.download_document';
  static const send = 'einvoice.send';
}
