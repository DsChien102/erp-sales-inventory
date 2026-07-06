import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'check_duplicate_product_code_query.dart';
import 'product_duplicate_match_dto.dart';

@QueryHandlerFor(CheckDuplicateProductCodeQuery)
final class CheckDuplicateProductCodeQueryHandler
    implements IQueryHandler<CheckDuplicateProductCodeQuery, List<ProductDuplicateMatchDto>> {
  CheckDuplicateProductCodeQueryHandler({
    required IProductDuplicateChecker duplicateChecker,
  }) : _duplicateChecker = duplicateChecker;

  final IProductDuplicateChecker _duplicateChecker;

  @override
  Future<List<ProductDuplicateMatchDto>> handle(
    CheckDuplicateProductCodeQuery query,
  ) async {
    final matches = await _duplicateChecker.findMatches(
      tenantId: TenantId(query.tenantId),
      sku: _optionalSku(query.sku),
      barcode: _optionalBarcode(query.barcode),
      excludeProductId: query.excludeProductId == null ? null : ProductId(query.excludeProductId!),
    );

    return matches.map(ProductDuplicateMatchDto.fromDomain).toList(growable: false);
  }

  Sku? _optionalSku(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return Sku(trimmed);
  }

  Barcode? _optionalBarcode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return Barcode(trimmed);
  }
}
