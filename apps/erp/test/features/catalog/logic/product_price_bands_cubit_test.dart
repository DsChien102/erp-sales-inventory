import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/logic/product_price_bands_cubit.dart';
import 'package:erp/features/catalog/logic/product_price_bands_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductPriceRepository extends Fake implements ProductPriceRepository {
  _MockProductPriceRepository({required this.onListUnitPriceBands});

  final Future<ProductUnitPriceBandsDto> Function(String productId) onListUnitPriceBands;

  @override
  Future<ProductUnitPriceBandsDto> listUnitPriceBands(String productId) {
    return onListUnitPriceBands(productId);
  }
}

void main() {
  group('ProductPriceBandsCubit (H14)', () {
    test('1. missing base unit emits ProductPriceBandsMissingBaseUnit', () async {
      final repo = _MockProductPriceRepository(
        onListUnitPriceBands: (productId) async {
          throw const AppException(CatalogErrorCodes.missingBaseUnit);
        },
      );

      final cubit = ProductPriceBandsCubit(
        productPriceRepository: repo,
        productId: 'prod-1',
      );

      await cubit.loadPriceBands();

      expect(cubit.state, isA<ProductPriceBandsMissingBaseUnit>());
    });

    test('2. other error emits ProductPriceBandsFailure with catalog message', () async {
      final repo = _MockProductPriceRepository(
        onListUnitPriceBands: (productId) async {
          throw const AppException(
            AppErrorCode.noPermission,
            serverMessage: 'Permission denied',
          );
        },
      );

      final cubit = ProductPriceBandsCubit(
        productPriceRepository: repo,
        productId: 'prod-1',
      );

      await cubit.loadPriceBands();

      expect(cubit.state, isA<ProductPriceBandsFailure>());
      final failure = cubit.state as ProductPriceBandsFailure;
      expect(failure.error, 'Bạn không có quyền thực hiện thao tác này.');
    });
  });
}
