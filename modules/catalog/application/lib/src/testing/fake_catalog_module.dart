import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Scenario ids aligned with `docs/themes/TH-02-product-pricing/harness/07-api-contracts.md`.
abstract final class FakeCatalogScenario {
  static const guidedCreateOk = 'guided_create_ok';
  static const guidedCreateDupSku = 'guided_create_dup_sku';
  static const guidedCreateDupBarcode = 'guided_create_dup_barcode';
  static const guidedCreateMissingName = 'guided_create_missing_name';
  static const guidedCreateNoImages = 'guided_create_no_images';
  static const guidedCreatePermissionDenied = 'guided_create_permission_denied';
}

/// Configurable [ICatalogModule] for widget and presentation tests.
final class FakeCatalogModule implements ICatalogModule {
  FakeCatalogModule({this.scenario = FakeCatalogScenario.guidedCreateOk});

  final String scenario;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is CreateProductCommand) {
      return _handleCreateProduct<TResult>(command as CreateProductCommand);
    }
    throw UnimplementedError('Unexpected command: ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is CheckDuplicateProductCodeQuery) {
      return _handleCheckDuplicate<TResult>(
        query as CheckDuplicateProductCodeQuery,
      );
    }
    throw UnimplementedError('Unexpected query: ${query.runtimeType}');
  }

  TResult _handleCreateProduct<TResult>(CreateProductCommand command) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreatePermissionDenied:
        throw ApplicationException('Permission denied');
      case FakeCatalogScenario.guidedCreateDupSku:
        throw DuplicateSkuException(
          sku: command.sku ?? 'SKU-001',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      case FakeCatalogScenario.guidedCreateDupBarcode:
        throw DuplicateBarcodeException(
          barcode: command.barcode ?? '8901234567890',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      case FakeCatalogScenario.guidedCreateMissingName:
        throw ValidationException('Product name is required.');
      case FakeCatalogScenario.guidedCreateNoImages:
        return CreateProductResult(
          productId: 'product-new-1',
          readinessSummary: ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
            blockers: [
              if (command.baseUnitName == null ||
                  command.baseUnitName!.trim().isEmpty)
                const ReadinessBlockerDto(
                  code: ReadinessBlockerCode.missingBaseUnit,
                  message: 'Thiếu đơn vị cơ sở',
                  group: 'units',
                ),
              const ReadinessBlockerDto(
                code: ReadinessBlockerCode.missingImage,
                message: 'Chưa có ảnh sản phẩm',
                group: 'profile',
              ),
              const ReadinessBlockerDto(
                code: ReadinessBlockerCode.missingPrice,
                message: 'Thiếu giá',
                group: 'pricing',
              ),
            ],
          ),
        ) as TResult;
      case FakeCatalogScenario.guidedCreateOk:
      default:
        return CreateProductResult(
          productId: 'product-new-1',
          readinessSummary: ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
            blockers: [
              if (command.baseUnitName == null ||
                  command.baseUnitName!.trim().isEmpty)
                const ReadinessBlockerDto(
                  code: ReadinessBlockerCode.missingBaseUnit,
                  message: 'Thiếu đơn vị cơ sở',
                  group: 'units',
                ),
              const ReadinessBlockerDto(
                code: ReadinessBlockerCode.missingPrice,
                message: 'Thiếu giá',
                group: 'pricing',
              ),
            ],
          ),
        ) as TResult;
    }
  }

  TResult _handleCheckDuplicate<TResult>(
    CheckDuplicateProductCodeQuery query,
  ) {
    switch (scenario) {
      case FakeCatalogScenario.guidedCreateDupSku:
        final sku = query.sku?.trim();
        if (sku != null && sku.isNotEmpty) {
          return [
            ProductDuplicateMatchDto(
              field: ProductDuplicateField.sku,
              productId: 'product-existing-1',
              productName: 'Existing Product',
              matchedValue: sku,
            ),
          ] as TResult;
        }
        return <ProductDuplicateMatchDto>[] as TResult;
      case FakeCatalogScenario.guidedCreateDupBarcode:
        final barcode = query.barcode?.trim();
        if (barcode != null && barcode.isNotEmpty) {
          return [
            ProductDuplicateMatchDto(
              field: ProductDuplicateField.barcode,
              productId: 'product-existing-1',
              productName: 'Existing Product',
              matchedValue: barcode,
            ),
          ] as TResult;
        }
        return <ProductDuplicateMatchDto>[] as TResult;
      default:
        return <ProductDuplicateMatchDto>[] as TResult;
    }
  }
}
