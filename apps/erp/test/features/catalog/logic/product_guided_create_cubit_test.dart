import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/product_guided_create_cubit.dart';
import 'package:erp/features/catalog/logic/product_guided_create_state.dart';
import 'package:erp/features/catalog/presentation/models/product_image_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_catalog_backend.dart';
import '../support/fake_catalog_repositories.dart';
import '../support/fake_catalog_scenario.dart';

class _CustomProductRepository extends FakeProductRepository {
  _CustomProductRepository({
    required super.backend,
    this.onCreateGuided,
  });

  final Future<CreateGuidedProductResult> Function(CreateGuidedProductInput input)? onCreateGuided;

  @override
  Future<CreateGuidedProductResult> createGuided(CreateGuidedProductInput input) {
    if (onCreateGuided != null) {
      return onCreateGuided!(input);
    }
    return super.createGuided(input);
  }
}

void main() {
  group('ProductGuidedCreateCubit (H9 & R1-2)', () {
    late FakeCatalogBackend backend;
    late FakeMeasurementUnitRepository unitRepo;
    late FakeCustomFieldRepository customFieldRepo;
    late FakeProductPriceRepository priceRepo;

    setUp(() {
      backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      unitRepo = FakeMeasurementUnitRepository(backend: backend);
      customFieldRepo = FakeCustomFieldRepository(backend: backend);
      priceRepo = FakeProductPriceRepository(backend: backend);
    });

    ProductGuidedCreateCubit buildCubit(FakeProductRepository prodRepo) {
      final cubit = ProductGuidedCreateCubit(
        productRepository: prodRepo,
        measurementUnitRepository: unitRepo,
        productPriceRepository: priceRepo,
        customFieldRepository: customFieldRepo,
      );
      // Pre-fill valid required fields to pass client validations
      cubit.updateName('Sản phẩm thử nghiệm');
      cubit.updateBaseUnit('Hộp');
      cubit.updateBaseCost('100000');
      cubit.updatePricingMethod('manual');
      cubit.updateManualListPrice('150000');
      return cubit;
    }

    test('1. duplicate SKU from server jumps to step 0 and extracts details', () async {
      final prodRepo = _CustomProductRepository(
        backend: backend,
        onCreateGuided: (input) async {
          throw const AppException(
            CatalogErrorCodes.duplicateSku,
            details: {
              'value': 'SKU-EXISTING',
              'existing_product_id': 'prod-999',
              'existing_product_name': 'Sản phẩm trùng SKU',
            },
          );
        },
      );

      final cubit = buildCubit(prodRepo);
      cubit.setStep(3); // Start at step 3

      await cubit.submit();

      expect(cubit.state.activeStepIndex, 0);
      expect(cubit.state.skuError, 'SKU "SKU-EXISTING" đã được sử dụng');
      expect(cubit.state.duplicateProductId, 'prod-999');
      expect(cubit.state.duplicateProductName, 'Sản phẩm trùng SKU');
    });

    test('2. validation error from server jumps to step 0 and shows validation errors', () async {
      final prodRepo = _CustomProductRepository(
        backend: backend,
        onCreateGuided: (input) async {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'Tên sản phẩm không hợp lệ từ máy chủ.',
          );
        },
      );

      final cubit = buildCubit(prodRepo);
      cubit.setStep(4);

      await cubit.submit();

      expect(cubit.state.activeStepIndex, 0);
      expect(cubit.state.showValidationErrors, isTrue);
      expect(cubit.state.status, ProductGuidedCreateStatus.error);
      expect(cubit.state.errorMessage, 'Tên sản phẩm không hợp lệ từ máy chủ.');
    });

    test('2b. known server validation message maps to TH-02 6.4 text (R2-4)', () async {
      final prodRepo = _CustomProductRepository(
        backend: backend,
        onCreateGuided: (input) async {
          throw const AppException(
            AppErrorCode.validation,
            serverMessage: 'product name is required',
          );
        },
      );

      final cubit = buildCubit(prodRepo);
      cubit.setStep(4);

      await cubit.submit();

      expect(cubit.state.activeStepIndex, 0);
      expect(cubit.state.showValidationErrors, isTrue);
      expect(cubit.state.errorMessage, 'Tên nội bộ không được bỏ trống');
    });

    test('3. permission denied or generic error does not jump to step 0', () async {
      final prodRepo = _CustomProductRepository(
        backend: backend,
        onCreateGuided: (input) async {
          throw const AppException(
            AppErrorCode.noPermission,
            serverMessage: 'Permission denied',
          );
        },
      );

      final cubit = buildCubit(prodRepo);
      cubit.setStep(3);

      await cubit.submit();

      expect(cubit.state.activeStepIndex, 3);
      expect(cubit.state.status, ProductGuidedCreateStatus.error);
      expect(cubit.state.errorMessage, contains('Bạn không có quyền thực hiện thao tác này.'));
    });

    test('4. removeImageAt shifts coverImageIndex when removing an image before cover', () {
      final prodRepo = FakeProductRepository(backend: backend);
      final cubit = ProductGuidedCreateCubit(
        productRepository: prodRepo,
        measurementUnitRepository: unitRepo,
        productPriceRepository: priceRepo,
        customFieldRepository: customFieldRepo,
      );

      // Add 3 images
      cubit.emit(
        cubit.state.copyWith(
          imageDrafts: [
            const ProductImageDraft(localPath: 'path-0', storageKey: 'key-0'),
            const ProductImageDraft(localPath: 'path-1', storageKey: 'key-1'),
            const ProductImageDraft(localPath: 'path-2', storageKey: 'key-2'),
          ],
          coverImageIndex: 2,
        ),
      );

      // Remove image at index 0 (before cover 2)
      cubit.removeImageAt(0);

      expect(cubit.state.imageDrafts.length, 2);
      expect(cubit.state.coverImageIndex, 1);
    });

    test('5. setStep(5) loads store price rule when entering price band step', () async {
      final prodRepo = FakeProductRepository(backend: backend);
      final cubit = ProductGuidedCreateCubit(
        productRepository: prodRepo,
        measurementUnitRepository: unitRepo,
        productPriceRepository: priceRepo,
        customFieldRepository: customFieldRepo,
      );

      expect(priceRepo.calls, isNot(contains('getStorePriceRule')));

      // Set to step 5 (Price band)
      cubit.setStep(5);
      await Future<void>.delayed(Duration.zero);

      expect(priceRepo.calls, contains('getStorePriceRule'));
      expect(cubit.state.activeStepIndex, 5);
    });

    test('t93_sp03_uploading_image_blocks_save', () async {
      final prodRepo = FakeProductRepository(backend: backend);
      final cubit = buildCubit(prodRepo);

      cubit.emit(
        cubit.state.copyWith(
          imageDrafts: [
            const ProductImageDraft(
              localPath: '/tmp/test.png',
              status: ProductImageUploadStatus.uploading,
            ),
          ],
        ),
      );

      expect(cubit.state.isUploadingImages, isTrue);
      expect(cubit.state.canSubmit, isFalse);

      await cubit.submit();

      expect(cubit.state.status, ProductGuidedCreateStatus.error);
      expect(cubit.state.errorMessage, 'Đang tải ảnh lên, vui lòng đợi.');
    });
  });
}
