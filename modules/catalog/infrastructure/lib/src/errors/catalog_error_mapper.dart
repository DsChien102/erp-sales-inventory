import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

Object mapCatalogRpcError(RpcException error) {
  final message = error.message.toLowerCase();

  if (message.contains('duplicate sku')) {
    return DuplicateSkuException(sku: _extractQuoted(error.message) ?? '');
  }

  if (message.contains('duplicate barcode')) {
    return DuplicateBarcodeException(
      barcode: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('duplicate measurement unit') ||
      message.contains('duplicate product unit')) {
    return DuplicateMeasurementUnitNameException(
      name: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('missing base unit') || message.contains('base_unit_not_found')) {
    return MissingBaseUnitException();
  }

  if (message.contains('not_basic_stock_mode')) {
    return NotBasicStockModeException();
  }

  if (message.contains('stale_stock_quantity')) {
    return StaleStockQuantityException();
  }

  if (message.contains('validation_exception')) {
    return ValidationException(_stripPrefix(error.message));
  }

  if (message.contains('product name is required')) {
    return ApplicationException('Product name is required.');
  }

  if (message.contains('product not found')) {
    return ApplicationException('Product not found');
  }

  if (message.contains('not authenticated') ||
      message.contains('permission denied') ||
      message.contains('actor mismatch')) {
    return ApplicationException(error.message, cause: error);
  }

  return ApplicationException(error.message, cause: error);
}

String _stripPrefix(String message) {
  return message.replaceFirst(RegExp(r'^validation_exception:\s*'), '');
}

String? _extractQuoted(String message) {
  final match = RegExp(r'"([^"]+)"').firstMatch(message);
  return match?.group(1);
}
