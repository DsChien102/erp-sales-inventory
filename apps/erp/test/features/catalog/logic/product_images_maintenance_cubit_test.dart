import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/catalog_rules.dart';
import 'package:erp/features/catalog/logic/product_images_maintenance_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({
    this.onUpdateImages,
  });

  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    required List<ProductImageMutationInput> images,
  })? onUpdateImages;

  @override
  Future<ProductImageUploadSlotDto> requestMaintenanceImageUpload({
    required String productId,
    required String fileName,
    required String contentType,
    required int byteSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateImages({
    required String productId,
    int? expectedVersion,
    required List<ProductImageMutationInput> images,
  }) {
    if (onUpdateImages != null) {
      return onUpdateImages!(
        productId: productId,
        expectedVersion: expectedVersion,
        images: images,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('ProductImagesMaintenanceCubit (H7 & R1-3)', () {
    test('1. submit preserves existing imageId in ProductImageMutationInput (R1-3)', () async {
      List<ProductImageMutationInput>? capturedImages;
      final repo = _MockProductRepository(
        onUpdateImages: ({required productId, expectedVersion, required images}) async {
          capturedImages = images;
        },
      );

      final cubit = ProductImagesMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-1',
        initialImages: ['storage-key-1'],
      );

      // Add image with existing imageId
      cubit.emit(
        cubit.state.copyWith(
          images: [
            const ProductImageStateItem(
              imageId: 'img-uuid-123',
              storageKey: 'storage-key-1',
              isPrimary: true,
            ),
          ],
        ),
      );

      await cubit.submit();

      expect(cubit.state.status, ProductImagesMaintenanceStatus.success);
      expect(capturedImages, isNotNull);
      expect(capturedImages!.length, 1);
      expect(capturedImages![0].imageId, 'img-uuid-123');
      expect(capturedImages![0].storageKey, 'storage-key-1');
      expect(capturedImages![0].isPrimary, isTrue);
    });

    test('2. submit fails with server validation message when saving 2 primary images', () async {
      final repo = _MockProductRepository(
        onUpdateImages: ({required productId, expectedVersion, required images}) async {
          // Throws validation error like backend check
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Không thể lưu nhiều hơn một ảnh chính.',
          );
        },
      );

      final cubit = ProductImagesMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-1',
        initialImages: [],
      );

      cubit.addImage(storageKey: 'key-1', slotId: 'slot-1');
      cubit.addImage(storageKey: 'key-2', slotId: 'slot-2');

      await cubit.submit();

      expect(cubit.state.status, ProductImagesMaintenanceStatus.failure);
      expect(cubit.state.errorMessage, 'Không thể lưu nhiều hơn một ảnh chính.');
    });

    test('3. submit fails with generic error fallback on unknown exception', () async {
      final repo = _MockProductRepository(
        onUpdateImages: ({required productId, expectedVersion, required images}) async {
          throw Exception('Network disconnected');
        },
      );

      final cubit = ProductImagesMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-1',
        initialImages: [],
      );

      await cubit.submit();

      expect(cubit.state.status, ProductImagesMaintenanceStatus.failure);
      expect(cubit.state.errorMessage, 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
    });

    test('4. checkUpdateImages rule validates at most one primary image', () {
      expect(
        () => checkUpdateImages(
          images: [
            const ProductImageMutationInput(
              storageKey: 'key-1',
              isPrimary: true,
              sortOrder: 0,
            ),
            const ProductImageMutationInput(
              storageKey: 'key-2',
              isPrimary: true,
              sortOrder: 1,
            ),
          ],
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.validation)),
      );
    });
  });
}
