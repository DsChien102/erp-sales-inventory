import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/logic/product_manual_base_price_cubit.dart';
import 'package:erp/features/catalog/logic/product_manual_base_price_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductPriceRepository extends Fake implements ProductPriceRepository {
  _MockProductPriceRepository({required this.onSetManualBasePrice});

  final Future<void> Function({
    required String productId,
    required double basePrice,
    String currency,
  }) onSetManualBasePrice;

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) {
    return onSetManualBasePrice(
      productId: productId,
      basePrice: basePrice,
      currency: currency,
    );
  }
}

void main() {
  group('ProductManualBasePriceCubit (H13)', () {
    test('1. negative price emits validation rule error message', () async {
      final repo = _MockProductPriceRepository(
        onSetManualBasePrice: ({required productId, required basePrice, currency = 'VND'}) async {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Giá cơ sở không được âm.',
          );
        },
      );

      final cubit = ProductManualBasePriceCubit(productPriceRepository: repo);

      await cubit.submitManualBasePrice(productId: 'prod-1', basePrice: -10000);

      expect(cubit.state.status, ProductManualBasePriceStatus.failure);
      expect(cubit.state.errorMessage, 'Giá cơ sở không được âm.');
    });

    test('2. missing base unit emits MISSING_BASE_UNIT error message', () async {
      final repo = _MockProductPriceRepository(
        onSetManualBasePrice: ({required productId, required basePrice, currency = 'VND'}) async {
          throw const AppException(
            CatalogErrorCodes.missingBaseUnit,
          );
        },
      );

      final cubit = ProductManualBasePriceCubit(productPriceRepository: repo);

      await cubit.submitManualBasePrice(productId: 'prod-1', basePrice: 50000);

      expect(cubit.state.status, ProductManualBasePriceStatus.failure);
      expect(cubit.state.errorMessage, 'Cần thiết lập đơn vị cơ sở trước.');
    });
  });
}
