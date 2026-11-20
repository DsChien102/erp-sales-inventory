import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/product_guided_create_cubit.dart';
import 'package:erp/features/catalog/logic/product_profile_maintenance_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_catalog_backend.dart';
import 'support/fake_catalog_repositories.dart';
import 'support/fake_catalog_scenario.dart';

class _CapturingProductRepository extends FakeProductRepository {
  _CapturingProductRepository({required super.backend});

  CreateGuidedProductInput? lastCreateInput;
  ProductTrackingMode? lastUpdateTrackingMode;
  bool? lastUpdateExpiryRequired;
  bool updateCalled = false;

  @override
  Future<CreateGuidedProductResult> createGuided(CreateGuidedProductInput input) {
    lastCreateInput = input;
    return super.createGuided(input);
  }

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
    updateCalled = true;
    lastUpdateTrackingMode = trackingMode;
    lastUpdateExpiryRequired = expiryRequired;
    return super.updateProfile(
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
  group('Catalog Tracking Mode & Expiry (Theme 2 / T7-G5-0b)', () {
    late FakeCatalogBackend backend;
    late _CapturingProductRepository repo;
    late FakeMeasurementUnitRepository unitRepo;
    late FakeProductPriceRepository priceRepo;
    late FakeCustomFieldRepository customFieldRepo;

    setUp(() {
      backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      repo = _CapturingProductRepository(backend: backend);
      unitRepo = FakeMeasurementUnitRepository(backend: backend);
      priceRepo = FakeProductPriceRepository(backend: backend);
      customFieldRepo = FakeCustomFieldRepository(backend: backend);
    });

    ProductGuidedCreateCubit buildGuidedCubit() {
      final cubit = ProductGuidedCreateCubit(
        productRepository: repo,
        measurementUnitRepository: unitRepo,
        productPriceRepository: priceRepo,
        customFieldRepository: customFieldRepo,
      );
      cubit.updateName('Sản phẩm thử nghiệm lô');
      cubit.updateBaseUnit('Hộp');
      cubit.updateBaseCost('100000');
      cubit.updatePricingMethod('manual');
      cubit.updateManualListPrice('150000');
      return cubit;
    }

    test('1. guided_create_sends_tracking: gửi đúng tracking_mode và expiry_required', () async {
      final cubit = buildGuidedCubit();
      cubit.setTrackingMode(ProductTrackingMode.lot);
      cubit.setExpiryRequired(true);

      await cubit.submit();

      expect(repo.lastCreateInput, isNotNull);
      expect(repo.lastCreateInput!.trackingMode, ProductTrackingMode.lot);
      expect(repo.lastCreateInput!.expiryRequired, isTrue);
    });

    test('2. expiry_toggle_disabled_until_lot: không thể bật expiry khi chưa chọn lot', () {
      final cubit = buildGuidedCubit();
      expect(cubit.state.trackingMode, ProductTrackingMode.none);
      expect(cubit.state.expiryRequired, isFalse);

      cubit.setExpiryRequired(true);
      expect(cubit.state.expiryRequired, isFalse, reason: 'Chưa chọn lot thì expiryRequired vẫn phải false');

      cubit.setTrackingMode(ProductTrackingMode.lot);
      expect(cubit.state.trackingMode, ProductTrackingMode.lot);

      cubit.setExpiryRequired(true);
      expect(cubit.state.expiryRequired, isTrue);
    });

    test('3. turning_lot_off_clears_expiry: tắt lot thì tự động tắt expiry', () {
      final cubit = buildGuidedCubit();
      cubit.setTrackingMode(ProductTrackingMode.lot);
      cubit.setExpiryRequired(true);
      expect(cubit.state.expiryRequired, isTrue);

      cubit.setTrackingMode(ProductTrackingMode.none);
      expect(cubit.state.trackingMode, ProductTrackingMode.none);
      expect(cubit.state.expiryRequired, isFalse);
    });

    test('4. profile_update_sends_tracking_only_when_changed: chỉ gửi khi có thay đổi', () async {
      final cubit = ProductProfileMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-lot-1',
        initialName: 'Thuốc thử nghiệm',
        initialTrackingMode: ProductTrackingMode.lot,
        initialExpiryRequired: false,
        trackingLocked: false,
      );

      // Chưa đổi gì, đổi tên thôi
      cubit.nameChanged('Thuốc thử nghiệm đổi tên');
      await cubit.submit();
      expect(repo.updateCalled, isTrue);
      expect(repo.lastUpdateTrackingMode, isNull);
      expect(repo.lastUpdateExpiryRequired, isNull);

      // Đổi expiryRequired
      repo.updateCalled = false;
      cubit.expiryRequiredChanged(true);
      await cubit.submit();
      expect(repo.lastUpdateTrackingMode, isNull);
      expect(repo.lastUpdateExpiryRequired, isTrue);

      // Đổi trackingMode sang none -> expiryRequired cũng đổi thành false (bằng initial false nên null)
      repo.updateCalled = false;
      cubit.trackingModeChanged(ProductTrackingMode.none);
      await cubit.submit();
      expect(repo.lastUpdateTrackingMode, ProductTrackingMode.none);
      expect(repo.lastUpdateExpiryRequired, isNull);

      // Tạo cubit với initialExpiryRequired là true -> khi tắt lot thì expiryRequired đổi sang false (khác initial)
      final cubit2 = ProductProfileMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-lot-2',
        initialName: 'Thuốc thử nghiệm 2',
        initialTrackingMode: ProductTrackingMode.lot,
        initialExpiryRequired: true,
        trackingLocked: false,
      );
      repo.updateCalled = false;
      cubit2.trackingModeChanged(ProductTrackingMode.none);
      await cubit2.submit();
      expect(repo.lastUpdateTrackingMode, ProductTrackingMode.none);
      expect(repo.lastUpdateExpiryRequired, isFalse);
    });

    test('5. toggles_locked_when_has_movements: khoá đổi khi đã có biến động kho', () {
      final cubit = ProductProfileMaintenanceCubit(
        productRepository: repo,
        productId: 'prod-locked-1',
        initialName: 'Thuốc đã xuất nhập kho',
        initialTrackingMode: ProductTrackingMode.lot,
        initialExpiryRequired: true,
        trackingLocked: true,
      );

      expect(cubit.state.trackingLocked, isTrue);

      cubit.trackingModeChanged(ProductTrackingMode.none);
      expect(cubit.state.trackingMode, ProductTrackingMode.lot, reason: 'Không đổi được trackingMode khi locked');

      cubit.expiryRequiredChanged(false);
      expect(cubit.state.expiryRequired, isTrue, reason: 'Không đổi được expiryRequired khi locked');
    });

    test('6. pcc_dto_defaults_when_keys_missing: nhận default khi JSON thiếu key tracking', () {
      final minimalJson = <String, dynamic>{
        'product_id': '00000000-0000-0000-0000-000000000001',
        'name': 'Sản phẩm mẫu',
        'is_soft_deleted': false,
      };

      final readModel = ProductControlCenterReadModel.fromJson(minimalJson);
      expect(readModel.trackingMode, ProductTrackingMode.none);
      expect(readModel.expiryRequired, isFalse);
      expect(readModel.hasInventoryMovements, isFalse);

      final summaryDto = ProductProfileSummaryDto(
        productId: '00000000-0000-0000-0000-000000000001',
        name: 'Sản phẩm mẫu',
        businessStatus: ProductBusinessStatus.active,
      );
      expect(summaryDto.trackingMode, ProductTrackingMode.none);
      expect(summaryDto.expiryRequired, isFalse);
      expect(summaryDto.hasInventoryMovements, isFalse);
    });
  });
}
