/// Cross-module permission codes seeded via IAM until owning modules declare
/// `@ModuleManifest`. Tracked in `modules/iam/docs/interim-domain.md`.
abstract final class InterimPermissionCodes {
  static const partnerRead = 'partner.read';
  static const partnerWrite = 'partner.write';
  static const settingsEinvoiceConfigure = 'settings.einvoice.configure';
}
