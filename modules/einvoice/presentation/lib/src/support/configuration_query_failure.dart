import 'package:vet45_einvoice_application/application.dart';

enum ConfigurationQueryFailure { permissionDenied, loadFailure }

ConfigurationQueryFailure mapConfigurationQueryFailure(Object error) {
  if (error is EInvoiceBlockedException && error.code == EInvoiceBlockedCodes.noPermission) {
    return ConfigurationQueryFailure.permissionDenied;
  }
  return ConfigurationQueryFailure.loadFailure;
}
