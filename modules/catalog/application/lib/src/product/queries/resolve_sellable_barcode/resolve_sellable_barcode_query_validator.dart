import 'package:vet45_shared_application/application.dart';

import 'resolve_sellable_barcode_query.dart';

final class ResolveSellableBarcodeQueryValidator
    implements ICommandValidator<ResolveSellableBarcodeQuery> {
  @override
  Future<void> validate(ResolveSellableBarcodeQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.storeId.trim().isEmpty) {
      throw ValidationException('Store id is required.');
    }
    if (query.barcode.trim().isEmpty) {
      throw ValidationException('Barcode is required.');
    }
  }
}
