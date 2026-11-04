import 'package:get_it/get_it.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/catalog_error_messages.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

/// ERP boundary mapping Catalog-owned sellability into Sales presentation VMs.
abstract final class SalesCatalogProductLookup {
  static SalesProductSearchFn bind([GetIt? getIt]) => bindSearch(getIt);

  static SalesProductSearchFn bindSearch([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (query, {int limit = 50}) => _search(di, query, limit: limit);
  }

  static SalesProductBarcodeResolveFn bindBarcode([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (barcode) => _resolveBarcode(di, barcode);
  }

  static SalesProductUnitsResolveFn bindResolve([GetIt? getIt]) => bindUnits(getIt);

  static SalesProductUnitsResolveFn bindUnits([GetIt? getIt]) {
    final di = getIt ?? GetIt.instance;
    return (product) => _resolveUnits(di, product);
  }

  static Future<List<SalesSellableProductVm>> _search(
    GetIt di,
    String query, {
    required int limit,
  }) async {
    try {
      final storeId = await di<SessionController>().requireActiveStoreId();
      final result = await di<ProductRepository>().searchSellable(
        storeId: storeId,
        keyword: query.trim(),
        limit: limit,
        offset: 0,
      );
      return result.map(_mapProduct).toList(growable: false);
    } on SalesExternalOperationException {
      rethrow;
    } catch (error) {
      // Keep the root cause visible — compose toast was swallowing every failure
      // as a generic "connection" message while DB search already succeeds.
      throw SalesExternalOperationException(_searchFailureMessage(error));
    }
  }

  static Future<List<SalesSellableProductVm>> _resolveBarcode(
    GetIt di,
    String barcode,
  ) async {
    try {
      final storeId = await di<SessionController>().requireActiveStoreId();
      final result = await di<ProductRepository>().resolveSellableBarcode(
        storeId: storeId,
        barcode: barcode.trim(),
      );
      return result.map(_mapProduct).toList(growable: false);
    } on SalesExternalOperationException {
      rethrow;
    } catch (_) {
      throw const SalesExternalOperationException(
        'Không thể tra cứu barcode. Vui lòng thử lại.',
      );
    }
  }

  static Future<SalesSellableProductVm> _resolveUnits(
    GetIt di,
    SalesSellableProductVm product,
  ) async {
    try {
      final storeId = await di<SessionController>().requireActiveStoreId();
      final currencyCode = product.referencePrice?.currencyCode;
      if (currencyCode == null) {
        throw const SalesExternalOperationException(
          'Sản phẩm không có thông tin tiền tệ hợp lệ.',
        );
      }
      final units = await di<ProductRepository>().listSellableUnits(
        storeId: storeId,
        productId: product.productId,
      );
      return product.copyWith(
        units: units
            .map((unit) => _mapUnit(unit, currencyCode: currencyCode))
            .toList(growable: false),
      );
    } on SalesExternalOperationException {
      rethrow;
    } catch (_) {
      throw const SalesExternalOperationException(
        'Không thể tải đơn vị bán. Vui lòng thử lại.',
      );
    }
  }

  static String _searchFailureMessage(Object error) {
    return catalogErrorMessage(
      error,
      fallback: 'Không thể tải sản phẩm. Vui lòng thử lại.',
    );
  }

  static SalesSellableProductVm _mapProduct(SellableProductDto product) {
    final units = product.units
        .map((unit) => _mapUnit(unit, currencyCode: product.currencyCode))
        .toList(growable: false);
    return SalesSellableProductVm(
      productId: product.productId,
      sku: product.sku ?? '',
      displayName: product.displayName,
      tradeName: product.tradeName,
      units: units,
      barcode: _firstBarcode(product.units),
      isBlocked: !product.isSellable,
      blockReason: product.blockReason,
      stockQuantity: _wholeQuantity(product.availableStockMicros),
      availabilityLabel: _availabilityLabel(product.availableStockMicros),
    );
  }

  static SalesProductUnitVm _mapUnit(
    SellableProductUnitDto unit, {
    required String currencyCode,
  }) {
    return SalesProductUnitVm(
      productUnitId: unit.productUnitId,
      unitCode: unit.unitCode,
      unitName: unit.unitName,
      unitPrice: MoneyDto(
        amountMinor: unit.listPriceMinor,
        currencyCode: currencyCode,
      ),
      isDefault: unit.isDefault,
      isBlocked: !unit.isActive || !unit.isSellable,
      blockReason: unit.blockReason,
      stockQuantity: _wholeQuantity(unit.availableStockMicros),
      listUnitPrice: MoneyDto(
        amountMinor: unit.listPriceMinor,
        currencyCode: currencyCode,
      ),
      floorUnitPrice: unit.floorPriceMinor == null
          ? null
          : MoneyDto(
              amountMinor: unit.floorPriceMinor!,
              currencyCode: currencyCode,
            ),
    );
  }

  static String? _firstBarcode(List<SellableProductUnitDto> units) {
    for (final unit in units) {
      final barcode = unit.barcode?.trim();
      if (barcode != null && barcode.isNotEmpty) return barcode;
    }
    return null;
  }

  static int? _wholeQuantity(int? micros) => micros == null ? null : micros ~/ 1000000;

  static String? _availabilityLabel(int? micros) {
    final quantity = _wholeQuantity(micros);
    return quantity == null ? null : 'Tồn $quantity';
  }
}
