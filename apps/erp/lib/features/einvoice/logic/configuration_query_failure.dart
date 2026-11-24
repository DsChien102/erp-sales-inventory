import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';

enum ConfigurationQueryFailure { permissionDenied, loadFailure }

ConfigurationQueryFailure mapConfigurationQueryFailure(Object error) {
  if (error is AppException && error.code == EInvoiceErrorCodes.noPermission) {
    return ConfigurationQueryFailure.permissionDenied;
  }
  return ConfigurationQueryFailure.loadFailure;
}
