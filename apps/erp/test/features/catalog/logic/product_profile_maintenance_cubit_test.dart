import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_profile_maintenance_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({required this.onUpdateProfile});

  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
  }) onUpdateProfile;

  @override
  Future<void> updateProfile({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
  }) {
    return onUpdateProfile(
      productId: productId,
      expectedVersion: expectedVersion,
      productName: productName,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      trackingMode: trackingMode,
      expiryRequired: expiryRequired,
    );
  }
}

void main() {
  group('ProductProfileMaintenanceCubit (H6)', () {
    ProductProfileMaintenanceCubit buildCubit(ProductRepository repo) {
      return ProductProfileMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-1',
        initialName: 'Thuốc A',
        initialSku: 'SKU-A',
        initialBarcode: 'BAR-A',
      );
    }

    test('1. duplicate SKU sets skuError', () async {
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          throw const AppException(CatalogErrorCodes.duplicateSku);
        },
      );

      final cubit = buildCubit(repo);
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.failure);
      expect(cubit.state.skuError, 'Mã SKU đã được sử dụng');
    });

    test('2. duplicate barcode sets barcodeError', () async {
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          throw const AppException(CatalogErrorCodes.duplicateBarcode);
        },
      );

      final cubit = buildCubit(repo);
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.failure);
      expect(cubit.state.barcodeError, 'Mã vạch đã được sử dụng');
    });

    test('3. stale product version sets errorMessage', () async {
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          throw const AppException(CatalogErrorCodes.staleProductVersion);
        },
      );

      final cubit = buildCubit(repo);
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.failure);
      expect(cubit.state.errorMessage, 'Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.');
    });

    test('4. product soft-deleted sets errorMessage', () async {
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          throw const AppException(
            CatalogErrorCodes.productNotFound,
            serverMessage: 'product is soft-deleted',
          );
        },
      );

      final cubit = buildCubit(repo);
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.failure);
      expect(cubit.state.errorMessage, contains('Sản phẩm không tồn tại hoặc đã bị xoá.'));
    });

    test('t93_sp05_barcode_trimmed_on_submit', () async {
      String? capturedBarcode;
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          capturedBarcode = barcode;
        },
      );

      final cubit = buildCubit(repo);
      cubit.barcodeChanged('  893123456  ');
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.success);
      expect(capturedBarcode, '893123456');
    });

    test('t93_sp05_empty_name_sets_name_error', () async {
      var repoCalled = false;
      final repo = _MockProductRepository(
        onUpdateProfile: ({
          required productId,
          required productName,
          commercialName,
          sku,
          barcode,
          description,
          note,
          expectedVersion,
          trackingMode,
          expiryRequired,
        }) async {
          repoCalled = true;
        },
      );

      final cubit = buildCubit(repo);
      cubit.nameChanged('   ');
      await cubit.submit();

      expect(cubit.state.status, ProductProfileMaintenanceStatus.failure);
      expect(cubit.state.nameError, 'Tên sản phẩm là bắt buộc');
      expect(repoCalled, isFalse);
    });
  });
}

