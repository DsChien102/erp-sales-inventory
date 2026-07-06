import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

ApplicationException mapCatalogRpcError(RpcException error) {
  final message = error.message.toLowerCase();

  if (message.contains('duplicate sku')) {
    return DuplicateSkuException(sku: _extractQuoted(error.message) ?? '');
  }

  if (message.contains('duplicate barcode')) {
    return DuplicateBarcodeException(
      barcode: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('product name is required')) {
    return ApplicationException('Product name is required.');
  }

  if (message.contains('not authenticated') ||
      message.contains('permission denied') ||
      message.contains('actor mismatch')) {
    return ApplicationException(error.message, cause: error);
  }

  return ApplicationException(error.message, cause: error);
}

String? _extractQuoted(String message) {
  final match = RegExp(r'"([^"]+)"').firstMatch(message);
  return match?.group(1);
}
